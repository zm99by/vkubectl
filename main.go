package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
)

type Pod struct {
	Name     string `json:"name"`
	READY    string `json:"ready"`
	STATUS   string `json:"status"`
	RESTARTS string `json:"restarts"`
	AGE      string `json:"age"`
}

func main() {
	pods := []Pod{
		//	{"my-pod-1", "1/1", "Running", "0", "14m"},
		//	{"my-pod-2", "1/1", "Running", "0", "44m"},
		//	{"my-pod-3", "0/1", "Pending", "0", "144m"},
	}

	for _, pod := range pods {
		fmt.Printf("%-25s %-20s %-15s %-10s %-5s\n", pod.Name, pod.READY, pod.STATUS, pod.RESTARTS, pod.AGE)
	}

	if len(os.Args) != 2 {
		fmt.Println("Usage: kubeclt [flags]")
		os.Exit(1)
	}

	newPod := Pod{
		Name:     os.Args[1],
		READY:    "1/1",
		STATUS:   "Running",
		RESTARTS: "0",
		AGE:      "14m",
	}

	pods = append(pods, newPod)

	file, err := os.Create("pods.txt")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer file.Close()

	b, err := json.Marshal(newPod)
	if err != nil {
		fmt.Println(err)
		return
	}

	_, err = file.Write(b)
	if err != nil {
		fmt.Println(err)
		return
	}

	data, err := ioutil.ReadFile("pods.txt")
	if err != nil {
		fmt.Println(err)
		return
	}

	var pod Pod
	err = json.Unmarshal(data, &pod)
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Printf("%-25s %-20s %-15s %-10s %-5s\n", "NAME", "READY", "STATUS", "RESTARTS", "AGE")
	for _, pod := range pods {
		fmt.Printf("%-25s %-20s %-15s %-10s %-5s\n", pod.Name, pod.READY, pod.STATUS, pod.RESTARTS, pod.AGE)
	}
	//	fmt.Printf("%-25s %-20s %-15s %-10s %-5s\n", "NAME", "READY", "STATUS", "RESTARTS", "AGE")
	//	fmt.Printf("%-25s %-20s %-15s %-10s %-5s\n", pod.Name, pod.READY, pod.STATUS, pod.RESTARTS, pod.AGE)

}
