[
  {
    "name": "postgres",
    "image": "${pg_image}",
    "cpu": ${pg_cpu},
    "memory": ${pg_memory},
    "networkMode": "awsvpc",
    "environment": [
	{"name": "POSTGRES_USER", "value": "postgres"},
	{"name": "POSTGRES_PASSWORD", "value": "postgres"}
    ],
    "portMappings": [
      {
        "containerPort": ${pg_port},
        "hostPort": ${pg_port}
      }
    ]
  }
]
