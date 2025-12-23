CREATE OR REPLACE FUNCTION bmsql_proc_delivery(
    IN w_id_in integer,
    IN o_carrier_id integer,
    IN ol_delivery_d timestamp,
    OUT delivered_o_id integer[]
) AS
$$
DECLARE
    d_id_val integer;
    no_o_id_val integer;
    o_c_id_val integer;
    total_amount decimal(12,2);
BEGIN
    delivered_o_id := ARRAY[]::integer[];
    
    FOR d_id_val IN 1..10 LOOP
        BEGIN
            SELECT no_o_id INTO no_o_id_val
            FROM bmsql_new_order
            WHERE no_w_id = w_id_in AND no_d_id = d_id_val
            ORDER BY no_o_id ASC
            LIMIT 1
            FOR UPDATE;

            IF no_o_id_val IS NOT NULL THEN
                DELETE FROM bmsql_new_order
                WHERE no_w_id = w_id_in AND no_d_id = d_id_val AND no_o_id = no_o_id_val;

                UPDATE bmsql_oorder
                SET o_carrier_id = o_carrier_id
                WHERE o_w_id = w_id_in AND o_d_id = d_id_val AND o_id = no_o_id_val
                RETURNING o_c_id INTO o_c_id_val;

                SELECT SUM(ol_amount) INTO total_amount
                FROM bmsql_order_line
                WHERE ol_w_id = w_id_in AND ol_d_id = d_id_val AND ol_o_id = no_o_id_val;

                UPDATE bmsql_order_line
                SET ol_delivery_d = ol_delivery_d
                WHERE ol_w_id = w_id_in AND ol_d_id = d_id_val AND ol_o_id = no_o_id_val;

                UPDATE bmsql_customer
                SET c_balance = c_balance + total_amount,
                    c_delivery_cnt = c_delivery_cnt + 1
                WHERE c_w_id = w_id_in AND c_d_id = d_id_val AND c_id = o_c_id_val;

                delivered_o_id := array_append(delivered_o_id, no_o_id_val);
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                CONTINUE;
        END;
    END LOOP;
END;
$$
LANGUAGE plpgsql;