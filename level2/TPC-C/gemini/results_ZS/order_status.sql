CREATE OR REPLACE FUNCTION order_status (
    in_w_id INT,
    in_d_id INT,
    in_c_id INT,
    in_c_last VARCHAR(16)
) RETURNS TABLE (
    c_id INT,
    c_first VARCHAR(16),
    c_middle CHAR(2),
    c_last VARCHAR(16),
    c_balance DECIMAL(12,2),
    o_id INT,
    o_entry_d TIMESTAMP,
    o_carrier_id INT,
    ol_supply_w_id INT[],
    ol_i_id INT[],
    ol_quantity INT[],
    ol_amount DECIMAL(6,2)[],
    ol_delivery_d TIMESTAMP[]
) AS $$
DECLARE
    v_c_id INT;
    v_c_first VARCHAR(16);
    v_c_middle CHAR(2);
    v_c_last VARCHAR(16);
    v_c_balance DECIMAL(12,2);
    
    v_o_id INT;
    v_o_entry_d TIMESTAMP;
    v_o_carrier_id INT;
    
    v_ol_supply_w_id INT[];
    v_ol_i_id INT[];
    v_ol_quantity INT[];
    v_ol_amount DECIMAL(6,2)[];
    v_ol_delivery_d TIMESTAMP[];
    
    customer_count INT;
    current_ol_count INT;
BEGIN
    -- Case 1: Customer is selected by number
    IF in_c_id IS NOT NULL THEN
        SELECT 
            c.c_id, c.c_first, c.c_middle, c.c_last, c.c_balance
        INTO 
            v_c_id, v_c_first, v_c_middle, v_c_last, v_c_balance
        FROM bmsql_customer AS c
        WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_id = in_c_id;
    -- Case 2: Customer is selected by last name
    ELSE
        SELECT count(*) INTO customer_count 
        FROM bmsql_customer AS c
        WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_last = in_c_last;

        -- Find the middle customer (n/2 rounded up)
        SELECT 
            c.c_id, c.c_first, c.c_middle, c.c_last, c.c_balance
        INTO 
            v_c_id, v_c_first, v_c_middle, v_c_last, v_c_balance
        FROM bmsql_customer AS c
        WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_last = in_c_last
        ORDER BY c.c_first ASC
        LIMIT 1 OFFSET (customer_count - 1) / 2;
    END IF;

    -- Find the customer's last order
    SELECT 
        o.o_id, o.o_entry_d, o.o_carrier_id
    INTO 
        v_o_id, v_o_entry_d, v_o_carrier_id
    FROM bmsql_oorder AS o
    WHERE o.o_w_id = in_w_id AND o.o_d_id = in_d_id AND o.o_c_id = v_c_id
    ORDER BY o.o_id DESC
    LIMIT 1;

    -- Retrieve all order lines for that order
    IF v_o_id IS NOT NULL THEN
        SELECT 
            array_agg(ol.ol_supply_w_id ORDER BY ol.ol_number),
            array_agg(ol.ol_i_id ORDER BY ol.ol_number),
            array_agg(ol.ol_quantity ORDER BY ol.ol_number),
            array_agg(ol.ol_amount ORDER BY ol.ol_number),
            array_agg(ol.ol_delivery_d ORDER BY ol.ol_number)
        INTO
            v_ol_supply_w_id,
            v_ol_i_id,
            v_ol_quantity,
            v_ol_amount,
            v_ol_delivery_d
        FROM bmsql_order_line AS ol
        WHERE ol.ol_w_id = in_w_id AND ol.ol_d_id = in_d_id AND ol.ol_o_id = v_o_id;
    END IF;

    -- Pad arrays to 15 elements if necessary
    current_ol_count := COALESCE(array_length(v_ol_i_id, 1), 0);

    IF current_ol_count < 15 THEN
        IF current_ol_count = 0 THEN
            v_ol_supply_w_id := ARRAY[]::INT[];
            v_ol_i_id := ARRAY[]::INT[];
            v_ol_quantity := ARRAY[]::INT[];
            v_ol_amount := ARRAY[]::DECIMAL(6,2)[];
            v_ol_delivery_d := ARRAY[]::TIMESTAMP[];
        END IF;

        FOR i IN (current_ol_count + 1)..15 LOOP
            v_ol_supply_w_id := array_append(v_ol_supply_w_id, 0);
            v_ol_i_id := array_append(v_ol_i_id, 0);
            v_ol_quantity := array_append(v_ol_quantity, 0);
            v_ol_amount := array_append(v_ol_amount, 0.0::DECIMAL(6,2));
            v_ol_delivery_d := array_append(v_ol_delivery_d, NULL::TIMESTAMP);
        END LOOP;
    END IF;

    -- Return the final result set
    RETURN QUERY SELECT
        v_c_id,
        v_c_first,
        v_c_middle,
        v_c_last,
        v_c_balance,
        v_o_id,
        v_o_entry_d,
        v_o_carrier_id,
        v_ol_supply_w_id,
        v_ol_i_id,
        v_ol_quantity,
        v_ol_amount,
        v_ol_delivery_d;
END;
$$ LANGUAGE plpgsql;