Step run set up kong api gateway

1. Run docker container
2. Setup KongA
   - Add Admin account
   - Setup Default Connection:
     - Name: default
     - Admin Url: http://kong:8001
3. Setup Kong Loopback

   - Add Kong Admin API as services: curl --location --request POST 'http://localhost:8001/services/' \
     --header 'Content-Type: application/json' \
     --data-raw '{
     "name": "admin-api",
     "host": "localhost",
     "port": 8001
     }'

   - Add Admin API route: curl --location --request POST 'http://localhost:8001/services/{service_id|service_name}/routes' \
     --header 'Content-Type: application/json' \
     --data-raw '{
     "paths": ["/admin-api"]
     }'

   - Enable Key Auth Plugin: curl -X POST http://localhost:8001/services/{service_id|service_name}/plugins \
     --data "name=key-auth"

   - Add Konga as Consumer: curl --location --request POST 'http://localhost:8001/consumers/' \
     --form 'username=konga' \
     --form 'custom_id=cebd360d-3de6-4f8f-81b2-31575fe9846a'

   - Create API Key for Konga:  
     curl --location --request POST 'http://localhost:8001/consumers/e7b420e2-f200-40d0-9d1a-a0df359da56e/key-auth'

   key: DOADm1NPtUyvG7ogi47dw1UqD6HYw4OD
