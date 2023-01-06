package utils

import "fmt"

func GetS3ObjectArn(bucket, key string) string {
	return fmt.Sprintf("arn:aws:s3:::%s/%s", bucket, key)
}

func GetS3ObjectFullPath(bucket, key string) string {
	return fmt.Sprintf("s3://%s/%s", bucket, key)
}

func GetS3OutputM3U8Arn(bucket, contentID string) string {
	return GetS3ObjectArn(bucket, getOutputM3U8Path(contentID))
}

func GetS3OutputPath(bucket, contentID string) string {
	return GetS3ObjectArn(bucket, getOutputPath(contentID))
}

func getOutputPath(contentID string) string {
	return fmt.Sprintf("%s/", contentID)
}

func getOutputM3U8Path(contentID string) string {
	return fmt.Sprintf("%s/%s.m3u8", contentID, contentID)
}
