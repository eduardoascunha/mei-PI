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
    OUT out_ol_amount decimal(12,2)[],
    OUT out_total_amount decimal(12,2),
    OUT out_c_last varchar(16),
    OUT out_c_credit char(2),
    OUT out_c_discount decimal(4,4),
    OUT out_i_name varchar(24)[],
    OUT out_i_price decimal(5,2)[],
    OUT out_s_quantity integer[],
    OUT out_brand_generic char[]
) AS
$$
DECLARE
    v_d_next_o_id integer;
    v_c_discount decimal(4,4);
    v_w_tax decimal(4,4);
    v_d_tax decimal(4,4);
    v_i_price decimal(5,2);
    v_i_name varchar(24);
    v_i_data varchar(50);
    v_s_quantity integer;
    v_s_data varchar(50);
    v_s_dist_info char(24);
    v_ol_amount decimal(12,2);
    v_total_amount decimal(12,2) := 0;
    v_o_all_local integer := 1;
    v_ol_idx integer;
    v_ol_count integer;
    v_item_found boolean;
BEGIN
    -- Get warehouse tax
    SELECT w_tax INTO v_w_tax FROM bmsql_warehouse WHERE w_id = in_w_id;
    out_w_tax := v_w_tax;

    -- Get district tax and next order ID
    SELECT d_tax, d_next_o_id INTO v_d_tax, v_d_next_o_id 
    FROM bmsql_district 
    WHERE d_w_id = in_w_id AND d_id = in_d_id 
    FOR UPDATE;
    
    out_d_tax := v_d_tax;
    out_o_id := v_d_next_o_id;

    -- Update district next order ID
    UPDATE bmsql_district 
    SET d_next_o_id = d_next_o_id + 1 
    WHERE d_w_id = in_w_id AND d_id = in_d_id;

    -- Get customer information
    SELECT c_discount, c_last, c_credit 
    INTO v_c_discount, out_c_last, out_c_credit 
    FROM bmsql_customer 
    WHERE c_w_id = in_w_id AND c_d_id = in_d_id AND c_id = in_c_id;
    
    out_c_discount := v_c_discount;

    -- Check for remote order lines
    FOR i IN 1..array_length(in_ol_supply_w_id, 1) LOOP
        IF in_ol_supply_w_id[i] != in_w_id THEN
            v_o_all_local := 0;
            EXIT;
        END IF;
    END LOOP;

    -- Set order entry date
    out_o_entry_d := CURRENT_TIMESTAMP;
    out_ol_cnt := array_length(in_ol_i_id, 1);

    -- Insert into order table
    INSERT INTO bmsql_oorder (o_w_id, o_d_id, o_id, o_c_id, o_carrier_id, o_ol_cnt, o_all_local, o_entry_d)
    VALUES (in_w_id, in_d_id, v_d_next_o_id, in_c_id, NULL, out_ol_cnt, v_o_all_local, out_o_entry_d);

    -- Insert into new_order table
    INSERT INTO bmsql_new_order (no_w_id, no_d_id, no_o_id)
    VALUES (in_w_id, in_d_id, v_d_next_o_id);

    -- Process each order line
    FOR i IN 1..out_ol_cnt LOOP
        -- Check if item exists
        SELECT i_price, i_name, i_data INTO v_i_price, v_i_name, v_i_data
        FROM bmsql_item WHERE i_id = in_ol_i_id[i];
        
        IF NOT FOUND THEN
            -- Rollback transaction for invalid item
            RAISE EXCEPTION 'Item number is not valid';
        END IF;

        -- Get stock information
        SELECT s_quantity, s_data, 
               CASE in_d_id 
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
               END INTO v_s_quantity, v_s_data, v_s_dist_info
        FROM bmsql_stock 
        WHERE s_w_id = in_ol_supply_w_id[i] AND s_i_id = in_ol_i_id[i]
        FOR UPDATE;

        -- Store original stock quantity
        out_s_quantity[i] := v_s_quantity;

        -- Update stock
        IF v_s_quantity >= in_ol_quantity[i] + 10 THEN
            UPDATE bmsql_stock 
            SET s_quantity = s_quantity - in_ol_quantity[i],
                s_ytd = s_ytd + in_ol_quantity[i],
                s_order_cnt = s_order_cnt + 1,
                s_remote_cnt = CASE WHEN in_ol_supply_w_id[i] != in_w_id THEN s_remote_cnt + 1 ELSE s_remote_cnt END
            WHERE s_w_id = in_ol_supply_w_id[i] AND s_i_id = in_ol_i_id[i];
        ELSE
            UPDATE bmsql_stock 
            SET s_quantity = s_quantity - in_ol_quantity[i] + 91,
                s_ytd = s_ytd + in_ol_quantity[i],
                s_order_cnt = s_order_cnt + 1,
                s_remote_cnt = CASE WHEN in_ol_supply_w_id[i] != in_w_id THEN s_remote_cnt + 1 ELSE s_remote_cnt END
            WHERE s_w_id = in_ol_supply_w_id[i] AND s_i_id = in_ol_i_id[i];
        END IF;

        -- Calculate order line amount
        v_ol_amount := in_ol_quantity[i] * v_i_price;
        out_ol_amount[i] := v_ol_amount;
        v_total_amount := v_total_amount + v_ol_amount;

        -- Determine brand generic
        IF v_i_data LIKE '%ORIGINAL%' AND v_s_data LIKE '%ORIGINAL%' THEN
            out_brand_generic[i] := 'B';
        ELSE
            out_brand_generic[i] := 'G';
        END IF;

        -- Store item information
        out_i_name[i] := v_i_name;
        out_i_price[i] := v_i_price;

        -- Insert order line
        INSERT INTO bmsql_order_line (ol_w_id, ol_d_id, ol_o_id, ol_number, ol_i_id, ol_delivery_d, ol_amount, ol_supply_w_id, ol_quantity, ol_dist_info)
        VALUES (in_w_id, in_d_id, v_d_next_o_id, i, in_ol_i_id[i], NULL, v_ol_amount, in_ol_supply_w_id[i], in_ol_quantity[i], v_s_dist_info);
    END LOOP;

    -- Calculate total amount with taxes and discount
    out_total_amount := v_total_amount * (1 - v_c_discount) * (1 + v_w_tax + v_d_tax);

EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$
LANGUAGE plpgsql;