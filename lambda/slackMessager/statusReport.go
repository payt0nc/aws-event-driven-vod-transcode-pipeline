package main

import (
	"fmt"
	"time"
)

// Slack Message Template
type StatusReport struct {
	Text   string  `json:"test,omitempty"`
	Blocks []Block `json:"blocks"`
}

type Block struct {
	Type     string    `json:"type"`
	Text     *Text     `json:"text,omitempty"`
	Fields   []Field   `json:"fields,omitempty"`
	Elements []Element `json:"elements,omitempty"`
}

type Text struct {
	Type  string `json:"type,omitempty"`
	Text  string `json:"text,omitempty"`
	Emoji bool   `json:"emoji,omitempty"`
}

type Field struct {
	Type string `json:"type,omitempty"`
	Text string `json:"text,omitempty"`
}

type Element struct {
	Type     string `json:"type,omitempty"`
	Text     string `json:"text,omitempty"`
	Emoji    bool   `json:"emoji,omitempty"`
	AltText  string `json:"alt_text,omitempty"`
	ImageURL string `json:"image_url,omitempty"`
}

func RenderStatusMessage(msg Event) StatusReport {
	return StatusReport{
		Blocks: []Block{
			{
				Type: "header",
				Text: &Text{
					Type:  "plain_text",
					Text:  "Transcoding Job Status",
					Emoji: true,
				},
			},
			{
				Type: "section",
				Fields: []Field{
					{
						Type: "mrkdwn",
						Text: fmt.Sprintf("*Job ID*\n%s", msg.JobID),
					},
					{
						Type: "mrkdwn",
						Text: fmt.Sprintf("*Status *\n%s", msg.Status),
					},
					{
						Type: "mrkdwn",
						Text: fmt.Sprintf("*Input*\n%s", msg.Input),
					},
					{
						Type: "mrkdwn",
						Text: fmt.Sprintf("*Output*\n%s", msg.Output),
					},
				},
			},
			{
				Type: "context",
				Elements: []Element{
					{
						Type: "mrkdwn",
						Text: fmt.Sprintf("Sent by %s at %s", msg.PipelineName, time.Now().Format("2006-01-02 15:04:05")),
					},
				},
			},
		},
	}
}
