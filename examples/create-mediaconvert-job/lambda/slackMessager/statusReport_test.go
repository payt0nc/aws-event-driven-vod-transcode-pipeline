package main

import (
	"fmt"
	"reflect"
	"testing"
	"time"
)

func TestRenderStatusMessage(t *testing.T) {
	type args struct {
		msg Event
	}
	tests := []struct {
		name string
		args args
		want StatusReport
	}{
		{
			name: "slack message test",
			args: args{
				msg: Event{
					ReportType:   "encoding",
					PipelineName: "test",
					JobID:        "testingID",
					Status:       "ERROR",
					Input:        "s3://input",
					Output:       "s3://output",
				},
			},
			want: StatusReport{
				Text: "",
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
								Text: fmt.Sprintf("*Job ID*\n%s", "testingID"),
							},
							{
								Type: "mrkdwn",
								Text: fmt.Sprintf("*Status *\n%s", "ERROR"),
							},
							{
								Type: "mrkdwn",
								Text: fmt.Sprintf("*Input*\n%s", "s3://input"),
							},
							{
								Type: "mrkdwn",
								Text: fmt.Sprintf("*Output*\n%s", "s3://output"),
							},
						},
					},
					{
						Type: "context",
						Elements: []Element{
							{
								Type: "mrkdwn",
								Text: fmt.Sprintf("Sent by %s at %s", "test", time.Now().Format("2006-01-02 15:04:05")),
							},
						},
					},
				},
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := RenderStatusMessage(tt.args.msg); !reflect.DeepEqual(got, tt.want) {
				t.Errorf("RenderStatusMessage() = %v, want %v", got, tt.want)
			}
		})
	}
}
