CREATE OR REPLACE FUNCTION bmsql_proc_order_status(
    IN in_w_id integer,
    IN in_d_id integer,
    IN in_c_id integer,
    IN in_c_last varchar(16),
    OUT out_c_id integer,
    OUT out_c_first varchar(16),
    OUT out_c_middle char(2),
    OUT out_c_balance decimal(12,2),
    OUT out_o_id integer,
    OUT out_o_entry_d varchar(24),
    OUT out_o_carrier_id integer,
    OUT out_ol_supply_w_id integer[],
    OUT out_ol_i_id integer[],
    OUT out_ol_quantity integer[],
    OUT out_ol_amount decimal(12,2)[],
    OUT out_ol_delivery_d timestamp[]
) AS $$
DECLARE
    customer_count integer;
    middle_offset integer;
    line_item RECORD;
    i integer := 1;
    tmp_o_entry_d timestamp;
BEGIN
    -- Step 1: Find the customer
    IF in_c_id IS NOT NULL THEN
        -- Case 1: Customer selected by C_ID
        SELECT c.c_balance, c.c_first, c.c_middle
        INTO out_c_balance, out_c_first, out_c_middle
        FROM bmsql_customer AS c
        WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_id = in_c_id;
        
        out_c_id := in_c_id;

    ELSE
        -- Case 2: Customer selected by C_LAST
        SELECT count(*) INTO customer_count
        FROM bmsql_customer AS c
        WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_last = in_c_last;

        IF customer_count > 0 THEN
            -- Calculate the offset for the middle customer (n/2 rounded up)
            middle_offset := (customer_count + 1) / 2 - 1;

            SELECT c.c_id, c.c_first, c.c_middle, c.c_balance
            INTO out_c_id, out_c_first, out_c_middle, out_c_balance
            FROM bmsql_customer AS c
            WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_last = in_c_last
            ORDER BY c.c_first ASC
            LIMIT 1 OFFSET middle_offset;
        END IF;
    END IF;

    -- If customer was not found, out_c_id will be NULL, and we can exit
    IF out_c_id IS NULL THEN
        RETURN;
    END IF;

    -- Step 2: Find the customer's last order
    SELECT o.o_id, o.o_entry_d, o.o_carrier_id
    INTO out_o_id, tmp_o_entry_d, out_o_carrier_id
    FROM bmsql_oorder AS o
    WHERE o.o_w_id = in_w_id AND o.o_d_id = in_d_id AND o.o_c_id = out_c_id
    ORDER BY o.o_id DESC
    LIMIT 1;

    -- Format the entry date as required
    out_o_entry_d := to_char(tmp_o_entry_d, 'YYYY-MM-DD HH24:MI:SS');

    -- If no order was found, exit
    IF out_o_id IS NULL THEN
        RETURN;
    END IF;

    -- Step 3: Retrieve the order lines for that order and pad arrays
    -- Initialize output arrays with default padded values
    out_ol_supply_w_id := array_fill(0, ARRAY[15]);
    out_ol_i_id := array_fill(0, ARRAY[15]);
    out_ol_quantity := array_fill(0, ARRAY[15]);
    out_ol_amount := array_fill(0.0::decimal(12,2), ARRAY[15]);
    out_ol_delivery_d := array_fill(NULL::timestamp, ARRAY[15]);

    FOR line_item IN
        SELECT ol.ol_i_id, ol.ol_supply_w_id, ol.ol_quantity, ol.ol_amount, ol.ol_delivery_d
        FROM bmsql_order_line AS ol
        WHERE ol.ol_w_id = in_w_id AND ol.ol_d_id = in_d_id AND ol.ol_o_id = out_o_id
    LOOP
        out_ol_i_id[i]        := line_item.ol_i_id;
        out_ol_supply_w_id[i] := line_item.ol_supply_w_id;
        out_ol_quantity[i]    := line_item.ol_quantity;
        out_ol_amount[i]      := line_item.ol_amount;
        out_ol_delivery_d[i]  := line_item.ol_delivery_d;
        i := i + 1;
    END LOOP;

END;
$$ LANGUAGE plpgsql;