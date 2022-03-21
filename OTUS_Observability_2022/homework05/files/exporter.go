package main

import (
        "bytes"
        "log"
        "net/http"
        "os"
        "strconv"
        "time"

        "github.com/prometheus/client_golang/prometheus"
        "github.com/prometheus/client_golang/prometheus/promauto"
        "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
        ooms = promauto.NewGauge (
                prometheus.GaugeOpts{
                        Name: "irqoff_oom_kill",
                        Help: "oom kill events",
                })
)

func main() {
        http.Handle("/metrics", promhttp.Handler())

        ticker := time.NewTicker(5 * time.Second)
        quit := make(chan struct{})
        go func() {
                for {
                        select {
                        case <-ticker.C:
                                content, err := os.ReadFile("/proc/vmstat")
                                result := []byte("")
                                if err != nil {
                                        log.Fatal(err)
                                }
                                match := bytes.Index(content, []byte("oom_kill"))
                                for _, c := range content[match+9 : len(content)] {
                                        if '0' <= c && c <= '9' {
                                                result = append(result, c)
                                        } else {
                                                break
                                        }
                                }
                                if s, err := strconv.ParseFloat(string(result), 64); err == nil {
                                        ooms.Set(s)
                                }
                                // fmt.Println(string(result))
                        case <-quit:
                                ticker.Stop()
                                return
                        }
                }
        }()
        log.Fatal(http.ListenAndServe(":8000", nil))
}
