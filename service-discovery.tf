### Creating a private DNS namespace, so that app could communicate with Postgres
resource "aws_service_discovery_private_dns_namespace" "mohi" {
  name              = "mohi"
  vpc               = aws_vpc.mohi_vpc.id
}

### Postgres' private DNS address (postgres.mohi)
resource "aws_service_discovery_service" "postgres" {
  name              = "postgres"
  dns_config {
    namespace_id    = aws_service_discovery_private_dns_namespace.mohi.id
    dns_records {
      ttl           = 5
      type          = "A"
    }
    routing_policy  = "MULTIVALUE"
  }
}
