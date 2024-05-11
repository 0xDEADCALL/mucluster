# Start server and set local with proper user and password
minio server /data --address :${MINIO_PORT} --console-address :${MINIO_CONSOLE_PORT} &

# Give some time for MinIO server to start running
sleep 5

mc alias set local http://localhost:${MINIO_PORT} ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD}

# Add access key to be used for the rest of the services
# THIS IS NOT SAFE!!
make_key=$( mc admin user svcacct info local ${AWS_ACCESS_KEY_ID} 2>/dev/null | wc -c)

# We get no info in the access key --> thus it doesn-t exist
if [[ $make_key -eq 0 ]]
then
    echo "Creating access key..."
    mc admin user svcacct add --access-key ${AWS_ACCESS_KEY_ID} --secret-key ${AWS_SECRET_ACCESS_KEY} local ${MINIO_ROOT_USER}
fi

# Make hive buckets
mc mb --ignore-existing local/hive

# Hive requires the warehouse key to exist and it won't create it 
# if using S3, thus we'll pipe a BLANK file to force it's creation in
# MinIO, as it doesn't support the concept of "empty folders"
echo "" | mc pipe local/hive/warehouse/_BLANK > /dev/null

# Make upload samples
if [[ ${INCLUDE_CSV_SAMPLES:-false} = true ]]
then
    mc mb --ignore-existing local/samples-csv-src
    mc cp --recursive /tmp/samples/ local/samples-csv-src
fi

echo -e "\nMinIO Server Running!"
# Block execution due to the server running as daemon
sleep infinity