brew install swagger-codegen
swagger-codegen generate -i http://localhost:7071/api/swagger.json -l typescript-axios -o client