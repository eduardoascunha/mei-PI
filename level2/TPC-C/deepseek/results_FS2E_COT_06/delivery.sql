CREATE OR REPLACE FUNCTION bmsql_proc_delivery(
    IN in_w_id integer,
    IN in_o_carrier_id integer,
    IN in_ol_delivery_d timestamp,
    OUT out_delivered_o_id integer[]
) AS
$$
DECLARE
    v_d_id integer;
    v_no_o_id integer;
    v_o_c_id integer;
    v_total_amount decimal(12,2);
    v_order_count integer := 0;
BEGIN
    out_delivered_o_id := '{}';
    
    FOR v_d_id IN 1..10 LOOP
        BEGIN
            SELECT no_o_id INTO v_no_o_id
            FROM bmsql_new_order
            WHERE no_w_id = in_w_id AND no_d_id = v_d_id
            ORDER BY no_o_id ASC
            LIMIT 1
            FOR UPDATE;

            IF v_no_o_id IS NOT NULL THEN
                DELETE FROM bmsql_new_order
                WHERE no_w_id = in_w_id AND no_d_id = v_d_id AND no_o_id = v_no_o_id;

                UPDATE bmsql_oorder
                SET o_carrier_id = in_o_carrier_id
                WHERE o_w_id = in_w_id AND o_d_id = v_d_id AND o_id = v_no_o_id
                RETURNING o_c_id INTO v_o_c_id;

                SELECT SUM(ol_amount) INTO v_total_amount
                FROM bmsql_order_line
                WHERE ol_w_id = in_w_id AND ol_d_id = v_d_id AND ol_o_id = v_no_o_id;

                UPDATE bmsql_order_line
                SET ol_delivery_d = in_ol_delivery_d
                WHERE ol_w_id = in_w_id AND ol_d_id = v_d_id AND ol_o_id = v_no_o_id;

                UPDATE bmsql_customer
                SET c_balance = c_balance + v_total_amount,
                    c_delivery_cnt = c_delivery_cnt + 1
                WHERE c_w_id = in_w_id AND c_d_id = v_d_id AND c_id = v_o_c_id;

                out_delivered_o_id := array_append(out_delivered_o_id, v_no_o_id);
                v_order_count := v_order_count + 1;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                CONTINUE;
        END;
    END LOOP;
END;
$$
LANGUAGE plpgsql;