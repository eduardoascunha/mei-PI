CREATE OR REPLACE FUNCTION delivery_transaction(
    w_id_in integer, 
    o_carrier_id integer, 
    ol_delivery_d timestamp, 
    OUT delivered_o_id integer[]
)
LANGUAGE plpgsql 
AS $$
DECLARE 
    district RECORD;
    no_o_id integer;
    o_c_id integer;
    ol_amount_sum decimal(6,2);
    delivered_orders integer[];
    order_count integer := 0;
BEGIN
    delivered_o_id := ARRAY[]::integer[];
    FOR district IN SELECT d_id FROM bmsql_district WHERE d_w_id = w_id_in ORDER BY d_id LOOP
        BEGIN
            SELECT no_o_id INTO no_o_id 
            FROM bmsql_new_order 
            WHERE no_w_id = w_id_in AND no_d_id = district.d_id 
            ORDER BY no_o_id LIMIT 1 FOR UPDATE;

            IF no_o_id IS NULL THEN
                CONTINUE;
            END IF;

            DELETE FROM bmsql_new_order 
            WHERE no_w_id = w_id_in AND no_d_id = district.d_id AND no_o_id = no_o_id;

            SELECT o_c_id INTO o_c_id 
            FROM bmsql_oorder 
            WHERE o_w_id = w_id_in AND o_d_id = district.d_id AND o_id = no_o_id;

            UPDATE bmsql_oorder 
            SET o_carrier_id = o_carrier_id 
            WHERE o_w_id = w_id_in AND o_d_id = district.d_id AND o_id = no_o_id;

            SELECT SUM(ol_amount) INTO ol_amount_sum 
            FROM bmsql_order_line 
            WHERE ol_w_id = w_id_in AND ol_d_id = district.d_id AND ol_o_id = no_o_id;

            UPDATE bmsql_order_line 
            SET ol_delivery_d = ol_delivery_d 
            WHERE ol_w_id = w_id_in AND ol_d_id = district.d_id AND ol_o_id = no_o_id;

            UPDATE bmsql_customer 
            SET c_balance = c_balance + ol_amount_sum, c_delivery_cnt = c_delivery_cnt + 1 
            WHERE c_w_id = w_id_in AND c_d_id = district.d_id AND c_id = o_c_id;

            delivered_o_id := array_append(delivered_o_id, no_o_id);
            order_count := order_count + 1;

            IF order_count % 10 = 0 THEN
                COMMIT;
            END IF;
        EXCEPTION 
            WHEN OTHERS THEN
                RAISE NOTICE 'Error delivering order for district %: %', district.d_id, SQLERRM;
                ROLLBACK;
        END;
    END LOOP;
    COMMIT;
END;
$$;