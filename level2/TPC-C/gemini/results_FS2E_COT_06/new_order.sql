CREATE OR REPLACE FUNCTION bmsql_proc_new_order(
    IN in_w_id integer,
    IN in_d_id integer,
    IN in_c_id integer,
    IN in_ol_supply_w_id integer[],
    IN in_ol_i_id integer[],
    IN in_ol_quantity integer[],
    OUT out_w_tax decimal(4, 4),
    OUT out_d_tax decimal(4, 4),
    OUT out_o_id integer,
    OUT out_o_entry_d timestamp,
    OUT out_ol_cnt integer,
    OUT out_total_amount decimal(12, 2),
    OUT out_c_last varchar(16),
    OUT out_c_credit char(2),
    OUT out_c_discount decimal(4, 4),
    OUT out_i_name varchar(24)[],
    OUT out_i_price decimal(5, 2)[],
    OUT out_s_quantity integer[],
    OUT out_ol_amount decimal(6, 2)[],
    OUT out_brand_generic char(1)[]
) AS $$
DECLARE
    v_all_local integer := 1;
    v_item_count integer;
    v_total_amount_sum decimal(12, 2) := 0;
    v_i_id integer;
    v_i_name varchar(24);
    v_i_price decimal(5, 2);
    v_i_data varchar(50);
    v_supply_w_id integer;
    v_ol_qty integer;
    v_s_qty integer;
    v_s_data varchar(50);
    v_s_dist_info char(24);
    v_new_s_qty integer;
    v_ol_amt decimal(6, 2);
    v_brand_gen char(1);
    v_ol_idx integer := 0;
    i integer;
BEGIN
    -- Pre-scan arrays to determine ol_cnt and all_local
    out_ol_cnt := 0;
    v_item_count := cardinality(in_ol_i_id);
    FOR i IN 1..v_item_count LOOP
        IF in_ol_i_id[i] IS NOT NULL AND in_ol_i_id[i] > 0 THEN
            out_ol_cnt := out_ol_cnt + 1;
            IF in_ol_supply_w_id[i] <> in_w_id THEN
                v_all_local := 0;
            END IF;
        END IF;
    END LOOP;

    -- Get Warehouse, Customer, and District information
    SELECT w.w_tax INTO out_w_tax FROM bmsql_warehouse AS w WHERE w.w_id = in_w_id;
    SELECT c.c_last, c.c_credit, c.c_discount INTO out_c_last, out_c_credit, out_c_discount FROM bmsql_customer AS c WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_id = in_c_id;

    -- Atomically increment d_next_o_id and get the new order ID and district tax
    UPDATE bmsql_district
    SET d_next_o_id = d_next_o_id + 1
    WHERE d_w_id = in_w_id AND d_id = in_d_id
    RETURNING d_tax, d_next_o_id - 1 INTO out_d_tax, out_o_id;

    out_o_entry_d := now();

    -- Insert into oorder and new_order
    INSERT INTO bmsql_oorder (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local)
    VALUES (out_o_id, in_d_id, in_w_id, in_c_id, out_o_entry_d, out_ol_cnt, v_all_local);

    INSERT INTO bmsql_new_order (no_o_id, no_d_id, no_w_id)
    VALUES (out_o_id, in_d_id, in_w_id);

    -- Process each order line
    FOR i IN 1..v_item_count LOOP
        -- Skip invalid items
        IF in_ol_i_id[i] IS NULL OR in_ol_i_id[i] <= 0 THEN
            CONTINUE;
        END IF;

        v_ol_idx := v_ol_idx + 1;
        v_i_id := in_ol_i_id[i];
        v_supply_w_id := in_ol_supply_w_id[i];
        v_ol_qty := in_ol_quantity[i];

        -- Get item information
        -- If item not found, this will raise a NO_DATA_FOUND exception and roll back the transaction
        SELECT it.i_price, it.i_name, it.i_data INTO v_i_price, v_i_name, v_i_data
        FROM bmsql_item AS it WHERE it.i_id = v_i_id;

        -- Get stock information
        SELECT s.s_quantity, s.s_data,
               CASE in_d_id
                   WHEN 1 THEN s.s_dist_01 WHEN 2 THEN s.s_dist_02 WHEN 3 THEN s.s_dist_03
                   WHEN 4 THEN s.s_dist_04 WHEN 5 THEN s.s_dist_05 WHEN 6 THEN s.s_dist_06
                   WHEN 7 THEN s.s_dist_07 WHEN 8 THEN s.s_dist_08 WHEN 9 THEN s.s_dist_09
                   WHEN 10 THEN s.s_dist_10
               END
        INTO v_s_qty, v_s_data, v_s_dist_info
        FROM bmsql_stock AS s WHERE s.s_i_id = v_i_id AND s.s_w_id = v_supply_w_id
        FOR UPDATE;

        -- Update stock quantity
        IF v_s_qty >= v_ol_qty + 10 THEN
            v_new_s_qty := v_s_qty - v_ol_qty;
        ELSE
            v_new_s_qty := v_s_qty - v_ol_qty + 91;
        END IF;

        -- Update stock table
        UPDATE bmsql_stock
        SET s_quantity = v_new_s_qty,
            s_ytd = s_ytd + v_ol_qty,
            s_order_cnt = s_order_cnt + 1,
            s_remote_cnt = s_remote_cnt + CASE WHEN v_supply_w_id <> in_w_id THEN 1 ELSE 0 END
        WHERE s_i_id = v_i_id AND s_w_id = v_supply_w_id;

        -- Calculate order line amount
        v_ol_amt := v_ol_qty * v_i_price;
        v_total_amount_sum := v_total_amount_sum + v_ol_amt;

        -- Determine brand-generic
        IF v_i_data LIKE '%ORIGINAL%' AND v_s_data LIKE '%ORIGINAL%' THEN
            v_brand_gen := 'B';
        ELSE
            v_brand_gen := 'G';
        END IF;

        -- Insert into order_line
        INSERT INTO bmsql_order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info)
        VALUES (out_o_id, in_d_id, in_w_id, v_ol_idx, v_i_id, v_supply_w_id, v_ol_qty, v_ol_amt, v_s_dist_info);

        -- Populate output arrays
        out_i_name[v_ol_idx] := v_i_name;
        out_i_price[v_ol_idx] := v_i_price;
        out_s_quantity[v_ol_idx] := v_s_qty;
        out_ol_amount[v_ol_idx] := v_ol_amt;
        out_brand_generic[v_ol_idx] := v_brand_gen;
    END LOOP;

    -- Calculate total amount
    out_total_amount := v_total_amount_sum * (1 - out_c_discount) * (1 + out_w_tax + out_d_tax);

END;
$$ LANGUAGE plpgsql;