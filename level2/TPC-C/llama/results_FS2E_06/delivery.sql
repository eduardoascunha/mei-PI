CREATE OR REPLACE FUNCTION bmsql_proc_delivery(
    IN w_id_in integer,
    IN o_carrier_id integer,
    IN ol_delivery_d timestamp,
    OUT delivered_o_id integer[]
) AS
$$
DECLARE
    d_id integer;
    no_o_id integer;
    c_id integer;
    ol_sum numeric;
    delivered_ids integer[];
    loop_counter integer := 0;
BEGIN
    FOR d_id IN 1..10 LOOP
        SELECT no_o_id INTO no_o_id 
        FROM bmsql_new_order 
        WHERE no_w_id = w_id_in AND no_d_id = d_id 
        ORDER BY no_o_id ASC LIMIT 1;

        IF no_o_id IS NOT NULL THEN
            DELETE FROM bmsql_new_order 
            WHERE no_w_id = w_id_in AND no_d_id = d_id AND no_o_id = no_o_id;

            UPDATE bmsql_oorder 
            SET o_carrier_id = o_carrier_id 
            WHERE o_w_id = w_id_in AND o_d_id = d_id AND o_id = no_o_id;

            SELECT o_c_id INTO c_id 
            FROM bmsql_oorder 
            WHERE o_w_id = w_id_in AND o_d_id = d_id AND o_id = no_o_id;

            SELECT sum(ol_amount) INTO ol_sum 
            FROM bmsql_order_line 
            WHERE ol_w_id = w_id_in AND ol_d_id = d_id AND ol_o_id = no_o_id;

            UPDATE bmsql_customer 
            SET c_balance = c_balance + ol_sum, c_delivery_cnt = c_delivery_cnt + 1 
            WHERE c_w_id = w_id_in AND c_d_id = d_id AND c_id = c_id;

            UPDATE bmsql_order_line 
            SET ol_delivery_d = ol_delivery_d 
            WHERE ol_w_id = w_id_in AND ol_d_id = d_id AND ol_o_id = no_o_id;

            delivered_ids := array_append(delivered_ids, no_o_id);
        END IF;

        IF loop_counter % 10 = 0 THEN
            COMMIT;
        END IF;

        loop_counter := loop_counter + 1;
    END LOOP;

    delivered_o_id := delivered_ids;
END;
$$
LANGUAGE plpgsql;