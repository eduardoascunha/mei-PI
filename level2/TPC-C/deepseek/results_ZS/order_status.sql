CREATE OR REPLACE FUNCTION order_status(
    in_w_id integer,
    in_d_id integer,
    in_c_id integer,
    in_c_last varchar(16)
) RETURNS TABLE (
    c_id integer,
    c_first varchar(16),
    c_middle char(2),
    c_balance decimal(12,2),
    o_id integer,
    o_entry_d varchar(24),
    o_carrier_id integer,
    ol_supply_w_id integer[],
    ol_i_id integer[],
    ol_quantity integer[],
    ol_amount decimal(12,2)[],
    ol_delivery_d timestamp[]
) LANGUAGE plpgsql AS $$
DECLARE
    v_customer_id integer;
    v_customer_first varchar(16);
    v_customer_middle char(2);
    v_customer_balance decimal(12,2);
    v_order_id integer;
    v_order_entry_d timestamp;
    v_order_carrier_id integer;
    v_order_line_count integer;
    v_ol_supply_w_id integer[];
    v_ol_i_id integer[];
    v_ol_quantity integer[];
    v_ol_amount decimal(12,2)[];
    v_ol_delivery_d timestamp[];
    v_customer_count integer;
    v_customer_row RECORD;
BEGIN
    IF in_c_id IS NOT NULL THEN
        SELECT c.c_id, c.c_first, c.c_middle, c.c_balance
        INTO v_customer_id, v_customer_first, v_customer_middle, v_customer_balance
        FROM bmsql_customer c
        WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_id = in_c_id;
    ELSE
        SELECT COUNT(*) INTO v_customer_count
        FROM bmsql_customer c
        WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_last = in_c_last;
        
        SELECT c.c_id, c.c_first, c.c_middle, c.c_balance
        INTO v_customer_id, v_customer_first, v_customer_middle, v_customer_balance
        FROM (
            SELECT c.c_id, c.c_first, c.c_middle, c.c_balance,
                   ROW_NUMBER() OVER (ORDER BY c.c_first) as row_num
            FROM bmsql_customer c
            WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_last = in_c_last
        ) c
        WHERE c.row_num = CEIL(v_customer_count::numeric / 2);
    END IF;

    SELECT o.o_id, o.o_entry_d, o.o_carrier_id
    INTO v_order_id, v_order_entry_d, v_order_carrier_id
    FROM bmsql_oorder o
    WHERE o.o_w_id = in_w_id AND o.o_d_id = in_d_id AND o.o_c_id = v_customer_id
    ORDER BY o.o_id DESC
    LIMIT 1;

    v_ol_supply_w_id := ARRAY[]::integer[];
    v_ol_i_id := ARRAY[]::integer[];
    v_ol_quantity := ARRAY[]::integer[];
    v_ol_amount := ARRAY[]::decimal(12,2)[];
    v_ol_delivery_d := ARRAY[]::timestamp[];

    FOR v_customer_row IN
        SELECT ol.ol_supply_w_id, ol.ol_i_id, ol.ol_quantity, ol.ol_amount, ol.ol_delivery_d
        FROM bmsql_order_line ol
        WHERE ol.ol_w_id = in_w_id AND ol.ol_d_id = in_d_id AND ol.ol_o_id = v_order_id
        ORDER BY ol.ol_number
    LOOP
        v_ol_supply_w_id := array_append(v_ol_supply_w_id, v_customer_row.ol_supply_w_id);
        v_ol_i_id := array_append(v_ol_i_id, v_customer_row.ol_i_id);
        v_ol_quantity := array_append(v_ol_quantity, v_customer_row.ol_quantity);
        v_ol_amount := array_append(v_ol_amount, v_customer_row.ol_amount);
        v_ol_delivery_d := array_append(v_ol_delivery_d, v_customer_row.ol_delivery_d);
    END LOOP;

    v_order_line_count := array_length(v_ol_supply_w_id, 1);
    IF v_order_line_count < 15 THEN
        FOR i IN (v_order_line_count + 1)..15 LOOP
            v_ol_supply_w_id := array_append(v_ol_supply_w_id, 0);
            v_ol_i_id := array_append(v_ol_i_id, 0);
            v_ol_quantity := array_append(v_ol_quantity, 0);
            v_ol_amount := array_append(v_ol_amount, 0.0);
            v_ol_delivery_d := array_append(v_ol_delivery_d, NULL);
        END LOOP;
    END IF;

    c_id := v_customer_id;
    c_first := v_customer_first;
    c_middle := v_customer_middle;
    c_balance := v_customer_balance;
    o_id := v_order_id;
    o_entry_d := to_char(v_order_entry_d, 'YYYY-MM-DD HH24:MI:SS');
    o_carrier_id := v_order_carrier_id;
    ol_supply_w_id := v_ol_supply_w_id;
    ol_i_id := v_ol_i_id;
    ol_quantity := v_ol_quantity;
    ol_amount := v_ol_amount;
    ol_delivery_d := v_ol_delivery_d;

    RETURN NEXT;
END;
$$;