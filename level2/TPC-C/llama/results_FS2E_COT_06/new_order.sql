CREATE OR REPLACE FUNCTION bmsql_proc_new_order(
    IN in_w_id integer,
    IN in_d_id integer,
    IN in_c_id integer,
    IN in_ol_supply_w_id integer[],
    IN in_ol_i_id integer[],
    IN in_ol_quantity integer[],
    OUT out_w_tax decimal(4,4),
    OUT out_d_tax decimal(4,4),
    OUT out_o_id integer,
    OUT out_o_entry_d timestamp,
    OUT out_ol_cnt integer,
    OUT out_total_amount decimal(12,2),
    OUT out_c_last varchar(16),
    OUT out_c_credit char(2),
    OUT out_c_discount decimal(4,4),
    OUT out_ol_amount decimal(12,2)[],
    OUT out_i_name varchar(24)[],
    OUT out_i_price decimal(5,2)[],
    OUT out_s_quantity integer[],
    OUT out_brand_generic char[]
) AS
$$
DECLARE
	v_c_id 		integer;
    v_d_next_o_id   integer;
    v_i_data        varchar(50);
    v_s_data        varchar(50);
    v_ol_cnt        integer := array_length(in_ol_i_id, 1);
    v_ol_all_local  integer;
    v_x             integer;
    v_rbk           integer;
    v_ol_amount     decimal(12,2);
    v_total_amount  decimal(12,2) := 0;
    v_i             integer;
    v_item_exists   boolean;
BEGIN
    v_rbk = (random() * 100)::int + 1;
    IF in_ol_i_id[v_ol_cnt] < 1 THEN
        RAISE EXCEPTION 'Invalid item number: %', in_ol_i_id[v_ol_cnt];
    END IF;

    SELECT w_tax INTO out_w_tax
    FROM bmsql_warehouse
    WHERE w_id = in_w_id;

    SELECT d_tax, d_next_o_id INTO out_d_tax, v_d_next_o_id
    FROM bmsql_district
    WHERE d_w_id = in_w_id AND d_id = in_d_id
    FOR UPDATE;

    out_o_id = v_d_next_o_id;
    v_d_next_o_id = v_d_next_o_id + 1;

    UPDATE bmsql_district
    SET d_next_o_id = v_d_next_o_id
    WHERE d_w_id = in_w_id AND d_id = in_d_id;

    SELECT c_last, c_credit, c_discount INTO out_c_last, out_c_credit, out_c_discount
    FROM bmsql_customer
    WHERE c_w_id = in_w_id AND c_d_id = in_d_id AND c_id = in_c_id;

    v_ol_all_local = 1;
    FOR v_i IN 1..v_ol_cnt LOOP
        IF in_ol_supply_w_id[v_i] <> in_w_id THEN
            v_ol_all_local = 0;
            EXIT;
        END IF;
    END LOOP;

    out_o_entry_d = now();
    out_ol_cnt = v_ol_cnt;

    INSERT INTO bmsql_oorder (
        o_w_id, o_d_id, o_id, o_c_id,
        o_carrier_id, o_ol_cnt, o_all_local, o_entry_d)
    VALUES (
        in_w_id, in_d_id, out_o_id, in_c_id,
        NULL, v_ol_cnt, v_ol_all_local, out_o_entry_d);

    INSERT INTO bmsql_new_order (
        no_w_id, no_d_id, no_o_id)
    VALUES (
        in_w_id, in_d_id, out_o_id);

    FOR v_i IN 1..v_ol_cnt LOOP
        SELECT i_price, i_name, i_data INTO out_i_price[v_i], out_i_name[v_i], v_i_data
        FROM bmsql_item
        WHERE i_id = in_ol_i_id[v_i];

        SELECT s_quantity, s_data, s_dist_01 INTO out_s_quantity[v_i], v_s_data, out_brand_generic[v_i]
        FROM bmsql_stock
        WHERE s_w_id = in_ol_supply_w_id[v_i] AND s_i_id = in_ol_i_id[v_i]
        FOR UPDATE;

        IF out_s_quantity[v_i] > in_ol_quantity[v_i] + 10 THEN
            out_s_quantity[v_i] = out_s_quantity[v_i] - in_ol_quantity[v_i];
        ELSE
            out_s_quantity[v_i] = out_s_quantity[v_i] + 91 - in_ol_quantity[v_i];
        END IF;

        UPDATE bmsql_stock SET
            s_quantity = out_s_quantity[v_i],
            s_ytd = s_ytd + in_ol_quantity[v_i],
            s_order_cnt = s_order_cnt + 1,
            s_remote_cnt = s_remote_cnt + CASE WHEN in_ol_supply_w_id[v_i] <> in_w_id THEN 1 ELSE 0 END
        WHERE s_w_id = in_ol_supply_w_id[v_i] AND s_i_id = in_ol_i_id[v_i];

        v_ol_amount = in_ol_quantity[v_i] * out_i_price[v_i];
        out_ol_amount[v_i] = v_ol_amount;
        v_total_amount = v_total_amount + v_ol_amount;

        IF v_i_data LIKE '%ORIGINAL%' AND v_s_data LIKE '%ORIGINAL%' THEN
            out_brand_generic[v_i] = 'B';
        ELSE
            out_brand_generic[v_i] = 'G';
        END IF;

        INSERT INTO bmsql_order_line (
            ol_w_id, ol_d_id, ol_o_id, ol_number,
            ol_i_id, ol_supply_w_id, ol_quantity,
            ol_amount, ol_dist_info, ol_delivery_d)
        VALUES (
            in_w_id, in_d_id, out_o_id, v_i,
            in_ol_i_id[v_i], in_ol_supply_w_id[v_i], in_ol_quantity[v_i],
            v_ol_amount, 'S_DIST_' || in_d_id, NULL);
    END LOOP;

    out_total_amount = v_total_amount * (1 + out_w_tax + out_d_tax) * (1 - out_c_discount);

    IF v_rbk = 1 THEN
        RAISE EXCEPTION 'Rollback due to rbk = 1';
    END IF;
END;
$$
LANGUAGE plpgsql;
