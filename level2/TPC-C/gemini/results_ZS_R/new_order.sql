CREATE OR REPLACE FUNCTION new_order(
    in_w_id integer,
    in_d_id integer,
    in_c_id integer,
    in_ol_supply_w_id integer[],
    in_ol_i_id integer[],
    in_ol_quantity integer[]
) RETURNS TABLE (
    w_tax decimal(4, 4),
    d_tax decimal(4, 4),
    o_id integer,
    o_entry_d timestamp,
    ol_cnt integer,
    total_amount decimal(12,2),
    c_last varchar(16),
    c_credit char(2),
    c_discount decimal(4,4),
    ol_amount decimal(6, 2)[],
    i_name varchar(24)[],
    i_price decimal(5,2)[],
    s_quantity integer[],
    brand_generic char(1)[]
) AS $$
DECLARE
    v_w_tax decimal(4, 4);
    v_d_tax decimal(4, 4);
    v_o_id integer;
    v_c_discount decimal(4, 4);
    v_c_last varchar(16);
    v_c_credit char(2);
    v_o_entry_d timestamp;
    v_ol_cnt integer;
    v_all_local integer := 1;
    v_total_amount decimal(12, 2) := 0;
    
    -- Per-item variables
    v_i_price decimal(5, 2);
    v_i_name varchar(24);
    v_i_data varchar(50);
    v_s_quantity integer;
    v_s_dist_info char(24);
    v_s_data varchar(50);
    v_ol_amount decimal(6, 2);
    v_brand_generic char(1);
    v_new_s_quantity integer;

    -- Output arrays
    v_ol_amount_arr decimal(6, 2)[] := ARRAY[]::decimal(6,2)[];
    v_i_name_arr varchar(24)[] := ARRAY[]::varchar(24)[];
    v_i_price_arr decimal(5, 2)[] := ARRAY[]::decimal(5,2)[];
    v_s_quantity_arr integer[] := ARRAY[]::integer[];
    v_brand_generic_arr char(1)[] := ARRAY[]::char(1)[];
BEGIN
    v_ol_cnt := array_length(in_ol_i_id, 1);
    v_o_entry_d := clock_timestamp();

    SELECT w.w_tax INTO v_w_tax
    FROM bmsql_warehouse AS w
    WHERE w.w_id = in_w_id;

    UPDATE bmsql_district AS d
    SET d_next_o_id = d.d_next_o_id + 1
    WHERE d.d_w_id = in_w_id AND d.d_id = in_d_id
    RETURNING d.d_tax, d.d_next_o_id - 1 INTO v_d_tax, v_o_id;

    SELECT c.c_discount, c.c_last, c.c_credit
    INTO v_c_discount, v_c_last, v_c_credit
    FROM bmsql_customer AS c
    WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_id = in_c_id;

    FOR i IN 1..v_ol_cnt LOOP
        IF in_ol_supply_w_id[i] <> in_w_id THEN
            v_all_local := 0;
            EXIT;
        END IF;
    END LOOP;

    INSERT INTO bmsql_oorder (o_w_id, o_d_id, o_id, o_c_id, o_carrier_id, o_ol_cnt, o_all_local, o_entry_d)
    VALUES (in_w_id, in_d_id, v_o_id, in_c_id, NULL, v_ol_cnt, v_all_local, v_o_entry_d);

    INSERT INTO bmsql_new_order (no_w_id, no_d_id, no_o_id)
    VALUES (in_w_id, in_d_id, v_o_id);

    FOR i IN 1..v_ol_cnt LOOP
        SELECT item.i_price, item.i_name, item.i_data
        INTO v_i_price, v_i_name, v_i_data
        FROM bmsql_item AS item
        WHERE item.i_id = in_ol_i_id[i];

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Item not found: %', in_ol_i_id[i];
        END IF;

        SELECT s.s_quantity, s.s_data,
               CASE in_d_id
                   WHEN 1 THEN s.s_dist_01 WHEN 2 THEN s.s_dist_02 WHEN 3 THEN s.s_dist_03
                   WHEN 4 THEN s.s_dist_04 WHEN 5 THEN s.s_dist_05 WHEN 6 THEN s.s_dist_06
                   WHEN 7 THEN s.s_dist_07 WHEN 8 THEN s.s_dist_08 WHEN 9 THEN s.s_dist_09
                   WHEN 10 THEN s.s_dist_10
               END
        INTO v_s_quantity, v_s_data, v_s_dist_info
        FROM bmsql_stock AS s
        WHERE s.s_i_id = in_ol_i_id[i] AND s.s_w_id = in_ol_supply_w_id[i];

        IF v_s_quantity >= in_ol_quantity[i] + 10 THEN
            v_new_s_quantity := v_s_quantity - in_ol_quantity[i];
        ELSE
            v_new_s_quantity := v_s_quantity - in_ol_quantity[i] + 91;
        END IF;

        UPDATE bmsql_stock AS s
        SET s_quantity = v_new_s_quantity,
            s_ytd = s.s_ytd + in_ol_quantity[i],
            s_order_cnt = s.s_order_cnt + 1,
            s_remote_cnt = s.s_remote_cnt + (CASE WHEN in_ol_supply_w_id[i] <> in_w_id THEN 1 ELSE 0 END)
        WHERE s.s_i_id = in_ol_i_id[i] AND s.s_w_id = in_ol_supply_w_id[i];

        v_ol_amount := in_ol_quantity[i] * v_i_price;
        v_total_amount := v_total_amount + v_ol_amount;

        IF v_i_data LIKE '%ORIGINAL%' AND v_s_data LIKE '%ORIGINAL%' THEN
            v_brand_generic := 'B';
        ELSE
            v_brand_generic := 'G';
        END IF;

        INSERT INTO bmsql_order_line (ol_w_id, ol_d_id, ol_o_id, ol_number, ol_i_id, ol_delivery_d, ol_amount, ol_supply_w_id, ol_quantity, ol_dist_info)
        VALUES (in_w_id, in_d_id, v_o_id, i, in_ol_i_id[i], NULL, v_ol_amount, in_ol_supply_w_id[i], in_ol_quantity[i], v_s_dist_info);

        v_ol_amount_arr := array_append(v_ol_amount_arr, v_ol_amount);
        v_i_name_arr := array_append(v_i_name_arr, v_i_name);
        v_i_price_arr := array_append(v_i_price_arr, v_i_price);
        v_s_quantity_arr := array_append(v_s_quantity_arr, v_s_quantity);
        v_brand_generic_arr := array_append(v_brand_generic_arr, v_brand_generic);
    END LOOP;

    v_total_amount := v_total_amount * (1 - v_c_discount) * (1 + v_w_tax + v_d_tax);

    w_tax := v_w_tax;
    d_tax := v_d_tax;
    o_id := v_o_id;
    o_entry_d := v_o_entry_d;
    ol_cnt := v_ol_cnt;
    total_amount := v_total_amount;
    c_last := v_c_last;
    c_credit := v_c_credit;
    c_discount := v_c_discount;
    ol_amount := v_ol_amount_arr;
    i_name := v_i_name_arr;
    i_price := v_i_price_arr;
    s_quantity := v_s_quantity_arr;
    brand_generic := v_brand_generic_arr;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;