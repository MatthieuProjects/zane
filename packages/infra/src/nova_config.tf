resource "kubernetes_config_map" "nova_config" {
  metadata {
    name      = "nova"
    namespace = kubernetes_namespace.zane.metadata.0.name
  }

  data = {
    "default.json" = jsonencode({
      "gateway" : {
        "intents" : 0,
        "shard" : 0,
        "shard_total" : 1
      },
      "rest" : {
        "server" : {
          "listening_adress" : "0.0.0.0:8080"
        },
        "ratelimiter_address" : "nova-ratelimit.zane.svc.cluster.local",
        "ratelimiter_port" : 8080,
        "discord" : {},
      },
      "webhook" : {
        "server" : {
          "listening_adress" : "0.0.0.0:8080"
        }
      },
      "cache" : {
        "toggles" : [
          "channels_cache",
          "guilds_cache",
          "guild_schedules_cache",
          "stage_instances_cache",
          "integrations_cache",
          "members_cache",
          "bans_cache",
          "reactions_cache",
          "messages_cache",
          "threads_cache",
          "invites_cache",
          "roles_cache",
          "automoderation_cache",
          "voice_states_cache"
        ]
      },
      "ratelimiter" : {
        "server" : {
          "listening_adress" : "0.0.0.0:8080"
        }
      },
      "monitoring" : {
        "enabled" : false,
      },
      "nats" : {
        "host" : "nats.zane.svc.cluster.local"
      },
      "redis" : {
        "url" : "redis://redis-master.zane.svc.cluster.local"
      },
    })
  }
}

variable "discord_token" {}
variable "discord_public_key" {}
variable "discord_client_id" {}

resource "kubernetes_secret" "nova_credentials" {
  metadata {
    name      = "nova"
    namespace = kubernetes_namespace.zane.metadata.0.name
  }

  data = {
    "NOVA__GATEWAY__TOKEN"               = var.discord_token,
    "NOVA__REST__DISCORD__TOKEN"         = var.discord_token,
    "NOVA__WEBHOOK__DISCORD__PUBLIC_KEY" = var.discord_public_key,
    "NOVA__WEBHOOK__DISCORD__CLIENT_ID"  = var.discord_client_id,
  }
}
