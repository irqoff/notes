listen {
  port = 4040
}

namespace "nginx" {
  format = "$remote_addr - $remote_user [$time_local] \"$request\" $status $body_bytes_sent $request_time \"$http_referer\" \"$http_user_agent\" \"$http_x_forwarded_for\""
  source {
    files = [
      "/var/log/nginx/upstream.access.log"
    ]
  }
}
