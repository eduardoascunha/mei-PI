CREATE OR REPLACE FUNCTION order_status_transaction(
    p_w_id integer,
    p_d_id integer,
    p_c_id integer,
    p_c_last varchar(16)
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
    v_o_id integer;
    v_o_entry_d timestamp;
    v_o_carrier_id integer;
    v_ol_count integer;
    v_ol_supply_w_id integer[];
    v_ol_i_id integer[];
    v_ol_quantity integer[];
    v_ol_amount decimal(12,2)[];
    v_ol_delivery_d timestamp[];
    v_customer_count integer;
    v_customer_pos integer;
    v_customer_rec RECORD;
BEGIN
    IF p_c_id IS NOT NULL THEN
        SELECT c.c_id, c.c_first, c.c_middle, c.c_balance
        INTO v_customer_id, c_first, c_middle, c_balance
        FROM bmsql_customer c
        WHERE c.c_w_id = p_w_id AND c.c_d_id = p_d_id AND c.c_id = p_c_id;
    ELSE
        SELECT COUNT(*) INTO v_customer_count
        FROM bmsql_customer c
        WHERE c.c_w_id = p_w_id AND c.c_d_id = p_d_id AND c.c_last = p_c_last;
        
        v_customer_pos := CEIL(v_customer_count::numeric / 2);
        
        SELECT c.c_id, c.c_first, c.c_middle, c.c_balance
        INTO v_customer_id, c_first, c_middle, c_balance
        FROM (
            SELECT c.c_id, c.c_first, c.c_middle, c.c_balance,
                   ROW_NUMBER() OVER (ORDER BY c.c_first) as rn
            FROM bmsql_customer c
            WHERE c.c_w_id = p_w_id AND c.c_d_id = p_d_id AND c.c_last = p_c_last
        ) c
        WHERE c.rn = v_customer_pos;
    END IF;

    c_id := v_customer_id;

    SELECT o.o_id, o.o_entry_d, o.o_carrier_id
    INTO v_o_id, v_o_entry_d, v_o_carrier_id
    FROM bmsql_oorder o
    WHERE o.o_w_id = p_w_id AND o.o_d_id = p_d_id AND o.o_c_id = v_customer_id
    ORDER BY o.o_id DESC
    LIMIT 1;

    o_id := v_o_id;
    o_entry_d := to_char(v_o_entry_d, 'YYYY-MM-DD HH24:MI:SS');
    o_carrier_id := v_o_carrier_id;

    SELECT 
        ARRAY_AGG(ol.ol_supply_w_id ORDER BY ol.ol_number),
        ARRAY_AGG(ol.ol_i_id ORDER BY ol.ol_number),
        ARRAY_AGG(ol.ol_quantity ORDER BY ol.ol_number),
        ARRAY_AGG(ol.ol_amount ORDER BY ol.ol_number),
        ARRAY_AGG(ol.ol_delivery_d ORDER BY ol.ol_number),
        COUNT(*)
    INTO 
        v_ol_supply_w_id,
        v_ol_i_id,
        v_ol_quantity,
        v_ol_amount,
        v_ol_delivery_d,
        v_ol_count
    FROM bmsql_order_line ol
    WHERE ol.ol_w_id = p_w_id AND ol.ol_d_id = p_d_id AND ol.ol_o_id = v_o_id;

    IF v_ol_count < 15 THEN
        v_ol_supply_w_id := v_ol_supply_w_id || array_fill(0, ARRAY[15 - v_ol_count]);
        v_ol_i_id := v_ol_i_id || array_fill(0, ARRAY[15 - v_ol_count]);
        v_ol_quantity := v_ol_quantity || array_fill(0, ARRAY[15 - v_ol_count]);
        v_ol_amount := v_ol_amount || array_fill(0.0::decimal(12,2), ARRAY[15 - v_ol_count]);
        v_ol_delivery_d := v_ol_delivery_d || array_fill(NULL::timestamp, ARRAY[15 - v_ol_count]);
    END IF;

    ol_supply_w_id := v_ol_supply_w_id;
    ol_i_id := v_ol_i_id;
    ol_quantity := v_ol_quantity;
    ol_amount := v_ol_amount;
    ol_delivery_d := v_ol_delivery_d;

    RETURN NEXT;
END;
$$;