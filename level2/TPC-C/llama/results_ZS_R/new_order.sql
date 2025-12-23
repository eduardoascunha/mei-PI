CREATE OR REPLACE FUNCTION new_order(
    p_w_id integer, 
    p_d_id integer, 
    p_c_id integer, 
    p_ol_supply_w_id integer[], 
    p_ol_i_id integer[], 
    p_ol_quantity integer[],
    OUT w_tax decimal(4,4), 
    OUT d_tax decimal(4,4), 
    OUT o_id integer, 
    OUT o_entry_d timestamp, 
    OUT ol_cnt integer, 
    OUT ol_amount decimal(12,2)[], 
    OUT total_amount decimal(12,2), 
    OUT c_last varchar(16), 
    OUT c_credit char(2), 
    OUT c_discount decimal(4,4), 
    OUT i_name varchar(24)[], 
    OUT i_price decimal(5,2)[], 
    OUT s_quantity integer[], 
    OUT brand_generic char[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    rbk integer;
    all_local integer;
    ol_number integer;
    i_data varchar(50);
    s_dist_info char(24);
    s_data varchar(50);
    s_ytd integer;
    s_order_cnt integer;
    s_remote_cnt integer;
BEGIN
    rbk := floor(random() * 100) + 1;
    ol_cnt := array_length(p_ol_i_id, 1);

    SELECT w_tax INTO w_tax FROM bmsql_warehouse WHERE w_id = p_w_id;

    SELECT d_tax, d_next_o_id INTO d_tax, o_id FROM bmsql_district WHERE d_w_id = p_w_id AND d_id = p_d_id FOR UPDATE;
    UPDATE bmsql_district SET d_next_o_id = o_id + 1 WHERE d_w_id = p_w_id AND d_id = p_d_id;

    SELECT c_last, c_credit, c_discount INTO c_last, c_credit, c_discount FROM bmsql_customer WHERE c_w_id = p_w_id AND c_d_id = p_d_id AND c_id = p_c_id;

    o_entry_d := now();
    all_local := 1;
    FOR i IN 1..ol_cnt LOOP
        IF p_ol_supply_w_id[i] != p_w_id THEN
            all_local := 0;
        END IF;
    END LOOP;

    INSERT INTO bmsql_oorder (o_w_id, o_d_id, o_id, o_c_id, o_carrier_id, o_ol_cnt, o_all_local, o_entry_d)
    VALUES (p_w_id, p_d_id, o_id, p_c_id, NULL, ol_cnt, all_local, o_entry_d);

    INSERT INTO bmsql_new_order (no_w_id, no_d_id, no_o_id) VALUES (p_w_id, p_d_id, o_id);

    total_amount := 0;
    FOR i IN 1..ol_cnt LOOP
        IF p_ol_i_id[i] < 1 OR p_ol_i_id[i] > 100000 THEN
            RAISE EXCEPTION 'Item number is not valid';
        END IF;

        SELECT i_name, i_price, i_data INTO i_name[i], i_price[i], i_data FROM bmsql_item WHERE i_id = p_ol_i_id[i];

        SELECT s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_data, s_ytd, s_order_cnt, s_remote_cnt
        INTO s_quantity[i], s_dist_info, s_dist_info, s_dist_info, s_dist_info, s_dist_info, s_dist_info, s_dist_info, s_dist_info, s_dist_info, s_dist_info, s_data, s_ytd, s_order_cnt, s_remote_cnt
        FROM bmsql_stock WHERE s_w_id = p_ol_supply_w_id[i] AND s_i_id = p_ol_i_id[i] FOR UPDATE;

        IF s_quantity[i] >= p_ol_quantity[i] + 10 THEN
            s_quantity[i] := s_quantity[i] - p_ol_quantity[i];
        ELSE
            s_quantity[i] := s_quantity[i] - p_ol_quantity[i] + 91;
        END IF;

        s_ytd := s_ytd + p_ol_quantity[i];
        s_order_cnt := s_order_cnt + 1;
        IF p_ol_supply_w_id[i] != p_w_id THEN
            s_remote_cnt := s_remote_cnt + 1;
        END IF;

        UPDATE bmsql_stock SET s_quantity = s_quantity[i], s_ytd = s_ytd, s_order_cnt = s_order_cnt, s_remote_cnt = s_remote_cnt
        WHERE s_w_id = p_ol_supply_w_id[i] AND s_i_id = p_ol_i_id[i];

        ol_amount[i] := p_ol_quantity[i] * i_price[i];
        total_amount := total_amount + ol_amount[i];

        IF i_data LIKE '%ORIGINAL%' AND s_data LIKE '%ORIGINAL%' THEN
            brand_generic[i] := 'B';
        ELSE
            brand_generic[i] := 'G';
        END IF;

        ol_number := i;
        s_dist_info := CASE p_d_id
            WHEN 1 THEN s_dist_01
            WHEN 2 THEN s_dist_02
            WHEN 3 THEN s_dist_03
            WHEN 4 THEN s_dist_04
            WHEN 5 THEN s_dist_05
            WHEN 6 THEN s_dist_06
            WHEN 7 THEN s_dist_07
            WHEN 8 THEN s_dist_08
            WHEN 9 THEN s_dist_09
            WHEN 10 THEN s_dist_10
        END;

        INSERT INTO bmsql_order_line (ol_w_id, ol_d_id, ol_o_id, ol_number, ol_i_id, ol_delivery_d, ol_amount, ol_supply_w_id, ol_quantity, ol_dist_info)
        VALUES (p_w_id, p_d_id, o_id, ol_number, p_ol_i_id[i], NULL, ol_amount[i], p_ol_supply_w_id[i], p_ol_quantity[i], s_dist_info);
    END LOOP;

    total_amount := total_amount * (1 - c_discount) * (1 + w_tax + d_tax);

    IF rbk = 1 AND p_ol_i_id[ol_cnt] > 100000 THEN
        RAISE EXCEPTION 'Item number is not valid';
    END IF;
END;
$$;