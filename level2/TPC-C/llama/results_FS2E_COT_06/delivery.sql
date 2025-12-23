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
    v_c_id integer;
    v_sum_ol_amount decimal(6,2);
    v_o_id integer;
    v_counter integer := 1;
BEGIN
    out_delivered_o_id := array_fill(0, ARRAY[10]);

    FOR v_d_id IN 1..10 LOOP
        BEGIN
            -- Get the oldest undelivered order for the district
            SELECT no_o_id INTO v_no_o_id
            FROM bmsql_new_order
            WHERE no_w_id = in_w_id AND no_d_id = v_d_id
            ORDER BY no_o_id ASC
            LIMIT 1
            FOR UPDATE;

            IF FOUND THEN
                -- Delete the new order
                DELETE FROM bmsql_new_order
                WHERE no_w_id = in_w_id AND no_d_id = v_d_id AND no_o_id = v_no_o_id;

                -- Update the order with the carrier id
                UPDATE bmsql_oorder
                SET o_carrier_id = in_o_carrier_id
                WHERE o_w_id = in_w_id AND o_d_id = v_d_id AND o_id = v_no_o_id
                RETURNING o_c_id INTO v_c_id;

                -- Update the order lines with the delivery date
                UPDATE bmsql_order_line
                SET ol_delivery_d = in_ol_delivery_d
                WHERE ol_w_id = in_w_id AND ol_d_id = v_d_id AND ol_o_id = v_no_o_id;

                -- Get the sum of the order line amounts
                SELECT sum(ol_amount) INTO v_sum_ol_amount
                FROM bmsql_order_line
                WHERE ol_w_id = in_w_id AND ol_d_id = v_d_id AND ol_o_id = v_no_o_id;

                -- Update the customer's balance and delivery count
                UPDATE bmsql_customer
                SET c_balance = c_balance + v_sum_ol_amount,
                    c_delivery_cnt = c_delivery_cnt + 1
                WHERE c_w_id = in_w_id AND c_d_id = v_d_id AND c_id = v_c_id;

                -- Store the delivered order id
                out_delivered_o_id[v_counter] := v_no_o_id;
                v_counter := v_counter + 1;
            END IF;

            -- Commit the transaction
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                -- Rollback the transaction if there's an error
                ROLLBACK;
        END;
    END LOOP;
END;
$$
LANGUAGE plpgsql;
