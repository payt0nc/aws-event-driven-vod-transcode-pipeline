package messages

type Event struct {
	ContentID string `json:"contentID"`
	ExeName   string `json:"executionName"`
	Status    string `json:"status"`
	// TODO: Extend this struct for more detailed messages.
}
