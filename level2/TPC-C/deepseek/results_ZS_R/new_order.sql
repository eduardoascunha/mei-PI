CREATE OR REPLACE FUNCTION bmsql_new_order(
    IN p_w_id integer,
    IN p_d_id integer,
    IN p_c_id integer,
    IN p_ol_supply_w_id integer[],
    IN p_ol_i_id integer[],
    IN p_ol_quantity integer[],
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
    OUT brand_generic char[],
    OUT status_message varchar(30)
) RETURNS record
LANGUAGE plpgsql
AS $$
DECLARE
    v_d_next_o_id integer;
    v_o_all_local integer := 1;
    v_ol_amount decimal(12,2);
    v_i_data varchar(50);
    v_s_data varchar(50);
    v_s_dist_info char(24);
    v_ol_number integer;
    v_item_not_found boolean := false;
    v_last_item_idx integer;
BEGIN
    -- Initialize output arrays
    ol_amount := array[]::decimal(12,2)[];
    i_name := array[]::varchar(24)[];
    i_price := array[]::decimal(5,2)[];
    s_quantity := array[]::integer[];
    brand_generic := array[]::char[];
    status_message := '';
    ol_cnt := array_length(p_ol_i_id, 1);

    -- Get warehouse tax
    SELECT w.w_tax INTO w_tax
    FROM bmsql_warehouse w
    WHERE w.w_id = p_w_id;

    -- Get district tax and next order ID
    SELECT d.d_tax, d.d_next_o_id INTO d_tax, v_d_next_o_id
    FROM bmsql_district d
    WHERE d.d_w_id = p_w_id AND d.d_id = p_d_id
    FOR UPDATE;

    -- Update district next order ID
    UPDATE bmsql_district
    SET d_next_o_id = v_d_next_o_id + 1
    WHERE d_w_id = p_w_id AND d_id = p_d_id;

    -- Get customer information
    SELECT c.c_last, c.c_credit, c.c_discount INTO c_last, c_credit, c_discount
    FROM bmsql_customer c
    WHERE c.c_w_id = p_w_id AND c.c_d_id = p_d_id AND c.c_id = p_c_id;

    -- Set order ID and entry date
    o_id := v_d_next_o_id;
    o_entry_d := CURRENT_TIMESTAMP;

    -- Check if any order line is remote
    FOR i IN 1..ol_cnt LOOP
        IF p_ol_supply_w_id[i] != p_w_id THEN
            v_o_all_local := 0;
            EXIT;
        END IF;
    END LOOP;

    -- Insert into orders table
    INSERT INTO bmsql_oorder (o_w_id, o_d_id, o_id, o_c_id, o_carrier_id, o_ol_cnt, o_all_local, o_entry_d)
    VALUES (p_w_id, p_d_id, o_id, p_c_id, NULL, ol_cnt, v_o_all_local, o_entry_d);

    -- Insert into new_order table
    INSERT INTO bmsql_new_order (no_w_id, no_d_id, no_o_id)
    VALUES (p_w_id, p_d_id, o_id);

    -- Process each order line
    FOR i IN 1..ol_cnt LOOP
        -- Check for unused item (last item with rbk=1)
        v_last_item_idx := ol_cnt;
        IF i = v_last_item_idx AND (random() * 100)::integer < 1 THEN
            -- Simulate unused item error
            v_item_not_found := true;
            status_message := 'Item number is not valid';
            EXIT;
        END IF;

        -- Get item information
        SELECT i.i_name, i.i_price, i.i_data INTO i_name[i], i_price[i], v_i_data
        FROM bmsql_item i
        WHERE i.i_id = p_ol_i_id[i];

        IF NOT FOUND THEN
            v_item_not_found := true;
            status_message := 'Item number is not valid';
            EXIT;
        END IF;

        -- Get stock information and update
        SELECT s.s_quantity, s.s_data, 
               CASE p_d_id 
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
               END INTO s_quantity[i], v_s_data, v_s_dist_info
        FROM bmsql_stock s
        WHERE s.s_i_id = p_ol_i_id[i] AND s.s_w_id = p_ol_supply_w_id[i]
        FOR UPDATE;

        -- Update stock
        IF s_quantity[i] >= p_ol_quantity[i] + 10 THEN
            UPDATE bmsql_stock
            SET s_quantity = s_quantity - p_ol_quantity[i],
                s_ytd = s_ytd + p_ol_quantity[i],
                s_order_cnt = s_order_cnt + 1,
                s_remote_cnt = CASE WHEN p_ol_supply_w_id[i] != p_w_id THEN s_remote_cnt + 1 ELSE s_remote_cnt END
            WHERE s_i_id = p_ol_i_id[i] AND s_w_id = p_ol_supply_w_id[i];
        ELSE
            UPDATE bmsql_stock
            SET s_quantity = s_quantity - p_ol_quantity[i] + 91,
                s_ytd = s_ytd + p_ol_quantity[i],
                s_order_cnt = s_order_cnt + 1,
                s_remote_cnt = CASE WHEN p_ol_supply_w_id[i] != p_w_id THEN s_remote_cnt + 1 ELSE s_remote_cnt END
            WHERE s_i_id = p_ol_i_id[i] AND s_w_id = p_ol_supply_w_id[i];
        END IF;

        -- Calculate order line amount
        v_ol_amount := p_ol_quantity[i] * i_price[i];
        ol_amount[i] := v_ol_amount;

        -- Determine brand generic
        IF v_i_data LIKE '%ORIGINAL%' AND v_s_data LIKE '%ORIGINAL%' THEN
            brand_generic[i] := 'B';
        ELSE
            brand_generic[i] := 'G';
        END IF;

        -- Insert order line
        v_ol_number := i;
        INSERT INTO bmsql_order_line (
            ol_w_id, ol_d_id, ol_o_id, ol_number, ol_i_id, ol_delivery_d,
            ol_amount, ol_supply_w_id, ol_quantity, ol_dist_info
        ) VALUES (
            p_w_id, p_d_id, o_id, v_ol_number, p_ol_i_id[i], NULL,
            v_ol_amount, p_ol_supply_w_id[i], p_ol_quantity[i], v_s_dist_info
        );
    END LOOP;

    -- If item not found, rollback
    IF v_item_not_found THEN
        ROLLBACK;
        RETURN;
    END IF;

    -- Calculate total amount
    total_amount := 0;
    FOR i IN 1..ol_cnt LOOP
        total_amount := total_amount + ol_amount[i];
    END LOOP;
    total_amount := total_amount * (1 - c_discount) * (1 + w_tax + d_tax);

    -- Commit transaction
    COMMIT;
END;
$$;