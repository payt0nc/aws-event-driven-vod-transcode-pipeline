package events

type ElementalEvent string

const (
	// $.detail.event
	// Ref: https://docs.aws.amazon.com/mediaconvert/latest/ug/mediaconvert_cwe_events.html
	// Ref: https://docs.aws.amazon.com/mediapackage/latest/ug/cloudwatch-events-example.html

	MCStatusProgressing      ElementalEvent = "PROGRESSING"
	MCStatusStatusUpdate     ElementalEvent = "STATUS_UPDATE"
	MCStatusComplete         ElementalEvent = "COMPLETE"
	MCStatusError            ElementalEvent = "ERROR"
	MCStatusNewWarning       ElementalEvent = "NEW_WARNING"
	MCStatusInputInformation ElementalEvent = "INPUT_INFORMATION"
	MCStatusQueueHop         ElementalEvent = "QUEUE_HOP"

	// Input notification events
	MPEventMaxIngestStreamsError ElementalEvent = "MaxIngestStreamsError"
	MPEventInputswitch           ElementalEvent = "InputSwitchEvent"

	// VOD Ingest Status Event
	MPEventIngestStart      ElementalEvent = "IngestStart"
	MPEventIngestError      ElementalEvent = "IngestError"
	MPEventIngestComplete   ElementalEvent = "IngestComplete"
	MPEventVodAssetPlayable ElementalEvent = "VodAssetPlayable"

	// Key Provider Event
	MPEventKeyProviderError ElementalEvent = "KeyProviderError"
)

func (e ElementalEvent) ToString() string {
	return string(e)
}
