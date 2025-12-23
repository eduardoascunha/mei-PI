CREATE OR REPLACE FUNCTION bmsql_proc_new_order(
    IN in_w_id integer,
    IN in_d_id integer,
    IN in_c_id integer,
    IN in_ol_supply_w_id integer[],
    IN in_ol_i_id integer[],
    IN in_ol_quantity integer[]
) RETURNS TABLE(
    out_w_tax decimal(4, 4),
    out_d_tax decimal(4, 4),
    out_o_id integer,
    out_o_entry_d timestamp,
    out_ol_cnt integer,
    out_total_amount decimal(12, 2),
    out_c_last varchar(16),
    out_c_credit char(2),
    out_c_discount decimal(4, 4),
    out_i_name varchar(24)[],
    out_i_price decimal(5, 2)[],
    out_s_quantity integer[],
    out_ol_amount decimal(6, 2)[],
    out_brand_generic char(1)[]
) AS $$
DECLARE
    v_w_tax         decimal(4, 4);
    v_d_tax         decimal(4, 4);
    v_d_next_o_id   integer;
    v_c_discount    decimal(4, 4);
    v_c_last        varchar(16);
    v_c_credit      char(2);
    v_ol_cnt        integer;
    v_o_all_local   integer := 1;
    v_o_entry_d     timestamp := now();
    v_total_amount  decimal(12, 2) := 0;
    v_i_price       decimal(5, 2);
    v_i_name        varchar(24);
    v_i_data        varchar(50);
    v_s_quantity    integer;
    v_s_data        varchar(50);
    v_s_dist_info   char(24);
    v_new_s_quantity integer;
    v_ol_amount     decimal(6, 2);
    v_brand_generic char(1);
    v_i             integer;
    
    res_i_name        varchar(24)[];
    res_i_price       decimal(5, 2)[];
    res_s_quantity    integer[];
    res_ol_amount     decimal(6, 2)[];
    res_brand_generic char(1)[];
BEGIN
    v_ol_cnt := array_length(in_ol_i_id, 1);

    SELECT w.w_tax INTO v_w_tax
    FROM bmsql_warehouse AS w
    WHERE w.w_id = in_w_id;

    SELECT d.d_tax, d.d_next_o_id INTO v_d_tax, v_d_next_o_id
    FROM bmsql_district AS d
    WHERE d.d_w_id = in_w_id AND d.d_id = in_d_id
    FOR UPDATE;

    UPDATE bmsql_district
    SET d_next_o_id = v_d_next_o_id + 1
    WHERE d_w_id = in_w_id AND d_id = in_d_id;

    SELECT c.c_discount, c.c_last, c.c_credit INTO v_c_discount, v_c_last, v_c_credit
    FROM bmsql_customer AS c
    WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_id = in_c_id;

    FOR v_i IN 1..v_ol_cnt LOOP
        IF in_ol_supply_w_id[v_i] <> in_w_id THEN
            v_o_all_local := 0;
            EXIT;
        END IF;
    END LOOP;

    INSERT INTO bmsql_oorder (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local)
    VALUES (v_d_next_o_id, in_d_id, in_w_id, in_c_id, v_o_entry_d, NULL, v_ol_cnt, v_o_all_local);

    INSERT INTO bmsql_new_order (no_o_id, no_d_id, no_w_id)
    VALUES (v_d_next_o_id, in_d_id, in_w_id);

    FOR v_i IN 1..v_ol_cnt LOOP
        SELECT i.i_price, i.i_name, i.i_data
        INTO v_i_price, v_i_name, v_i_data
        FROM bmsql_item AS i
        WHERE i.i_id = in_ol_i_id[v_i];

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Item number is not valid';
        END IF;

        SELECT s.s_quantity, s.s_data,
               CASE in_d_id
                   WHEN 1 THEN s.s_dist_01
                   WHEN 2 THEN s.s_dist_02
                   WHEN 3 THEN s.s_dist_03
                   WHEN 4 THEN s.s_dist_04
                   WHEN 5 THEN s.s_dist_05
                   WHEN 6 THEN s.s_dist_06
                   WHEN 7 THEN s.s_dist_07
                   WHEN 8 THEN s.s_dist_08
                   WHEN 9 THEN s.s_dist_09
                   WHEN 10 THEN s.s_dist_10
               END
        INTO v_s_quantity, v_s_data, v_s_dist_info
        FROM bmsql_stock AS s
        WHERE s.s_i_id = in_ol_i_id[v_i] AND s.s_w_id = in_ol_supply_w_id[v_i]
        FOR UPDATE;

        IF v_s_quantity >= in_ol_quantity[v_i] + 10 THEN
            v_new_s_quantity := v_s_quantity - in_ol_quantity[v_i];
        ELSE
            v_new_s_quantity := v_s_quantity - in_ol_quantity[v_i] + 91;
        END IF;

        UPDATE bmsql_stock
        SET s_quantity = v_new_s_quantity,
            s_ytd = s_ytd + in_ol_quantity[v_i],
            s_order_cnt = s_order_cnt + 1,
            s_remote_cnt = s_remote_cnt + (CASE WHEN in_ol_supply_w_id[v_i] <> in_w_id THEN 1 ELSE 0 END)
        WHERE s_i_id = in_ol_i_id[v_i] AND s_w_id = in_ol_supply_w_id[v_i];

        v_ol_amount := in_ol_quantity[v_i] * v_i_price;
        v_total_amount := v_total_amount + v_ol_amount;

        IF v_i_data LIKE '%ORIGINAL%' AND v_s_data LIKE '%ORIGINAL%' THEN
            v_brand_generic := 'B';
        ELSE
            v_brand_generic := 'G';
        END IF;

        INSERT INTO bmsql_order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_delivery_d, ol_quantity, ol_amount, ol_dist_info)
        VALUES (v_d_next_o_id, in_d_id, in_w_id, v_i, in_ol_i_id[v_i], in_ol_supply_w_id[v_i], NULL, in_ol_quantity[v_i], v_ol_amount, v_s_dist_info);

        res_i_name[v_i]       := v_i_name;
        res_i_price[v_i]      := v_i_price;
        res_s_quantity[v_i]   := v_s_quantity;
        res_ol_amount[v_i]    := v_ol_amount;
        res_brand_generic[v_i] := v_brand_generic;
    END LOOP;

    v_total_amount := v_total_amount * (1 - v_c_discount) * (1 + v_w_tax + v_d_tax);

    RETURN QUERY SELECT
        v_w_tax,
        v_d_tax,
        v_d_next_o_id,
        v_o_entry_d,
        v_ol_cnt,
        v_total_amount,
        v_c_last,
        v_c_credit,
        v_c_discount,
        res_i_name,
        res_i_price,
        res_s_quantity,
        res_ol_amount,
        res_brand_generic;

END;
$$ LANGUAGE plpgsql;