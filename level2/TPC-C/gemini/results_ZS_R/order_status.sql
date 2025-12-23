CREATE OR REPLACE FUNCTION order_status (
    in_w_id INTEGER,
    in_d_id INTEGER,
    in_c_id INTEGER,
    in_c_last VARCHAR(16)
) RETURNS TABLE (
    c_id INTEGER,
    c_first VARCHAR(16),
    c_middle CHAR(2),
    c_balance DECIMAL(12,2),
    o_id INTEGER,
    o_entry_d TIMESTAMP,
    o_carrier_id INTEGER,
    ol_supply_w_id INTEGER[],
    ol_i_id INTEGER[],
    ol_quantity INTEGER[],
    ol_amount DECIMAL(6,2)[],
    ol_delivery_d TIMESTAMP[]
) AS $$
DECLARE
    v_c_id INTEGER;
    v_c_first VARCHAR(16);
    v_c_middle CHAR(2);
    v_c_last VARCHAR(16);
    v_c_balance DECIMAL(12,2);
    v_o_id INTEGER;
    v_o_entry_d TIMESTAMP;
    v_o_carrier_id INTEGER;
    v_ol_supply_w_id INTEGER[];
    v_ol_i_id INTEGER[];
    v_ol_quantity INTEGER[];
    v_ol_amount DECIMAL(6,2)[];
    v_ol_delivery_d TIMESTAMP[];
    customer_count INTEGER;
    middle_offset INTEGER;
    num_items INTEGER;
BEGIN
    -- Find the customer
    IF in_c_id IS NULL THEN
        -- Case 2: Customer selected by last name
        SELECT count(*) INTO customer_count
        FROM bmsql_customer c
        WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_last = in_c_last;

        middle_offset := (customer_count + 1) / 2 - 1;

        SELECT c.c_id, c.c_first, c.c_middle, c.c_balance
        INTO v_c_id, v_c_first, v_c_middle, v_c_balance
        FROM bmsql_customer c
        WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_last = in_c_last
        ORDER BY c.c_first ASC
        LIMIT 1 OFFSET middle_offset;
    ELSE
        -- Case 1: Customer selected by customer number
        v_c_id := in_c_id;
        SELECT c.c_first, c.c_middle, c.c_balance
        INTO v_c_first, v_c_middle, v_c_balance
        FROM bmsql_customer c
        WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_id = v_c_id;
    END IF;

    -- Find the customer's last order
    SELECT o.o_id, o.o_entry_d, o.o_carrier_id
    INTO v_o_id, v_o_entry_d, v_o_carrier_id
    FROM bmsql_oorder o
    WHERE o.o_w_id = in_w_id AND o.o_d_id = in_d_id AND o.o_c_id = v_c_id
    ORDER BY o.o_id DESC
    LIMIT 1;

    -- If an order is found, get the order lines
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
        FROM bmsql_order_line ol
        WHERE ol.ol_w_id = in_w_id
          AND ol.ol_d_id = in_d_id
          AND ol.ol_o_id = v_o_id;
    END IF;

    -- Pad the arrays to 15 elements
    num_items := COALESCE(array_length(v_ol_i_id, 1), 0);

    IF num_items < 15 THEN
        IF num_items = 0 THEN
            v_ol_supply_w_id := ARRAY[]::INTEGER[];
            v_ol_i_id := ARRAY[]::INTEGER[];
            v_ol_quantity := ARRAY[]::INTEGER[];
            v_ol_amount := ARRAY[]::DECIMAL(6,2)[];
            v_ol_delivery_d := ARRAY[]::TIMESTAMP[];
        END IF;

        v_ol_supply_w_id := array_cat(v_ol_supply_w_id, array_fill(0, ARRAY[15 - num_items]));
        v_ol_i_id := array_cat(v_ol_i_id, array_fill(0, ARRAY[15 - num_items]));
        v_ol_quantity := array_cat(v_ol_quantity, array_fill(0, ARRAY[15 - num_items]));
        v_ol_amount := array_cat(v_ol_amount, array_fill(0.0::DECIMAL(6,2), ARRAY[15 - num_items]));
        v_ol_delivery_d := array_cat(v_ol_delivery_d, array_fill(NULL::TIMESTAMP, ARRAY[15 - num_items]));
    END IF;

    -- Return the results
    c_id := v_c_id;
    c_first := v_c_first;
    c_middle := v_c_middle;
    c_balance := v_c_balance;
    o_id := v_o_id;
    o_entry_d := v_o_entry_d;
    o_carrier_id := v_o_carrier_id;
    ol_supply_w_id := v_ol_supply_w_id;
    ol_i_id := v_ol_i_id;
    ol_quantity := v_ol_quantity;
    ol_amount := v_ol_amount;
    ol_delivery_d := v_ol_delivery_d;

    RETURN NEXT;

END;
$$ LANGUAGE plpgsql;