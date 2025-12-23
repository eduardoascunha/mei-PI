CREATE OR REPLACE FUNCTION delivery (
    w_id_in integer,
    o_carrier_id_in integer,
    ol_delivery_d_in timestamp
) RETURNS integer[] AS $$
DECLARE
    d_id integer;
    v_o_id integer;
    v_c_id integer;
    v_ol_total decimal(12, 2);
    delivered_o_ids integer[] := ARRAY[]::integer[];
BEGIN
    FOR d_id IN 1..10 LOOP
        SELECT no_o_id
        INTO v_o_id
        FROM bmsql_new_order
        WHERE no_w_id = w_id_in AND no_d_id = d_id
        ORDER BY no_o_id ASC
        LIMIT 1
        FOR UPDATE SKIP LOCKED;

        IF v_o_id IS NULL THEN
            CONTINUE;
        END IF;

        DELETE FROM bmsql_new_order
        WHERE no_w_id = w_id_in AND no_d_id = d_id AND no_o_id = v_o_id;

        UPDATE bmsql_oorder
        SET o_carrier_id = o_carrier_id_in
        WHERE o_w_id = w_id_in AND o_d_id = d_id AND o_id = v_o_id
        RETURNING o_c_id INTO v_c_id;

        WITH updated_ol AS (
            UPDATE bmsql_order_line
            SET ol_delivery_d = ol_delivery_d_in
            WHERE ol_w_id = w_id_in AND ol_d_id = d_id AND ol_o_id = v_o_id
            RETURNING ol_amount
        )
        SELECT SUM(updated_ol.ol_amount)
        INTO v_ol_total
        FROM updated_ol;

        UPDATE bmsql_customer
        SET c_balance = c_balance + v_ol_total,
            c_delivery_cnt = c_delivery_cnt + 1
        WHERE c_w_id = w_id_in AND c_d_id = d_id AND c_id = v_c_id;

        delivered_o_ids := array_append(delivered_o_ids, v_o_id);

    END LOOP;

    RETURN delivered_o_ids;
END;
$$ LANGUAGE plpgsql;