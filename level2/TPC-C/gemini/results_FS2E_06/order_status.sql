CREATE OR REPLACE FUNCTION bmsql_proc_order_status(
    IN in_w_id integer,
    IN in_d_id integer,
    IN in_c_id integer,
    IN in_c_last varchar(16),
    OUT out_c_id integer,
    OUT out_c_first varchar(16),
    OUT out_c_middle char(2),
    OUT out_c_last varchar(16),
    OUT out_c_balance decimal(12,2),
    OUT out_o_id integer,
    OUT out_o_entry_d timestamp,
    OUT out_o_carrier_id integer,
    OUT out_ol_supply_w_id integer[],
    OUT out_ol_i_id integer[],
    OUT out_ol_quantity integer[],
    OUT out_ol_amount decimal(6,2)[],
    OUT out_ol_delivery_d timestamp[]
) AS $$
DECLARE
    customer_count INTEGER;
    middle_offset INTEGER;
    ol_line RECORD;
    i integer := 0;
BEGIN
    -- Find the customer
    IF in_c_id IS NOT NULL THEN
        -- Case 1: Customer is selected by C_ID
        SELECT c.c_id, c.c_first, c.c_middle, c.c_last, c.c_balance
        INTO out_c_id, out_c_first, out_c_middle, out_c_last, out_c_balance
        FROM bmsql_customer AS c
        WHERE c.c_w_id = in_w_id
          AND c.c_d_id = in_d_id
          AND c.c_id = in_c_id;
    ELSE
        -- Case 2: Customer is selected by C_LAST
        SELECT count(*) INTO customer_count
        FROM bmsql_customer AS c
        WHERE c.c_w_id = in_w_id
          AND c.c_d_id = in_d_id
          AND c.c_last = in_c_last;

        IF customer_count > 0 THEN
            middle_offset := ceil(customer_count / 2.0) - 1;

            SELECT c.c_id, c.c_first, c.c_middle, c.c_last, c.c_balance
            INTO out_c_id, out_c_first, out_c_middle, out_c_last, out_c_balance
            FROM bmsql_customer AS c
            WHERE c.c_w_id = in_w_id
              AND c.c_d_id = in_d_id
              AND c.c_last = in_c_last
            ORDER BY c.c_first
            LIMIT 1 OFFSET middle_offset;
        END IF;
    END IF;

    IF out_c_id IS NULL THEN
        RETURN;
    END IF;

    -- Find the customer's last order
    SELECT o.o_id, o.o_entry_d, o.o_carrier_id
    INTO out_o_id, out_o_entry_d, out_o_carrier_id
    FROM bmsql_oorder AS o
    WHERE o.o_w_id = in_w_id
      AND o.o_d_id = in_d_id
      AND o.o_c_id = out_c_id
    ORDER BY o.o_id DESC
    LIMIT 1;

    IF out_o_id IS NULL THEN
        RETURN;
    END IF;

    -- Retrieve the order lines for that order
    FOR ol_line IN
        SELECT ol.ol_supply_w_id, ol.ol_i_id, ol.ol_quantity, ol.ol_amount, ol.ol_delivery_d
        FROM bmsql_order_line AS ol
        WHERE ol.ol_w_id = in_w_id
          AND ol.ol_d_id = in_d_id
          AND ol.ol_o_id = out_o_id
        ORDER BY ol.ol_number
    LOOP
        i := i + 1;
        out_ol_supply_w_id[i] := ol_line.ol_supply_w_id;
        out_ol_i_id[i] := ol_line.ol_i_id;
        out_ol_quantity[i] := ol_line.ol_quantity;
        out_ol_amount[i] := ol_line.ol_amount;
        out_ol_delivery_d[i] := ol_line.ol_delivery_d;
    END LOOP;

    -- Pad the order line arrays to 15 elements
    FOR j IN (i + 1) .. 15 LOOP
        out_ol_supply_w_id[j] := 0;
        out_ol_i_id[j] := 0;
        out_ol_quantity[j] := 0;
        out_ol_amount[j] := 0.0;
        out_ol_delivery_d[j] := NULL;
    END LOOP;

END;
$$ LANGUAGE plpgsql;