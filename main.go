package main

import (
	"fmt"
)

type Pod struct {
	Name     string
	READY    string
	STATUS   string
	RESTARTS string
	AGE      string
}

func main() {
	pods := []Pod{
		{"my-pod-1", "1/1", "Running", "0", "14m"},
		{"my-pod-2", "1/1", "Running", "0", "44m"},
		{"my-pod-3", "0/1", "Pending", "0", "144m"},
	}

	fmt.Printf("%-25s %-20s %-15s %-10s %-5s\n", "NAME", "READY", "STATUS", "RESTARTS", "AGE")
	for _, pod := range pods {
		fmt.Printf("%-25s %-20s %-15s %-10s %-5s\n", pod.Name, pod.READY, pod.STATUS, pod.RESTARTS, pod.AGE)
	}
}
