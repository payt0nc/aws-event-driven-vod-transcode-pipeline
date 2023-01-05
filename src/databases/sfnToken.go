package databases

import (
	"context"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/sirupsen/logrus"
)

type SFNToken struct {
	Name      string    `json:"name" dynamoav:"Name"`
	Token     string    `json:"token" dynamoav:"Token"`
	CreatedAt time.Time `json:"createdAt" dynamoav:"CreatedAt"`
}

type TokenTable struct {
	db        *dynamodb.Client
	tableName string
	logger    *logrus.Entry
}

func NewTokenTableClient(cfg aws.Config, tableName string, logger *logrus.Entry) TokenTable {
	return TokenTable{
		db:        dynamodb.NewFromConfig(cfg),
		tableName: tableName,
		logger:    logger,
	}
}

func (st SFNToken) GetKey() map[string]types.AttributeValue {
	name, _ := attributevalue.Marshal(st.Name)
	return map[string]types.AttributeValue{"Name": name}
}

func (tt TokenTable) GetSFNToken(ctx context.Context, sfnName string) (string, error) {
	var token SFNToken
	token.Name = sfnName
	output, err := tt.db.GetItem(ctx, &dynamodb.GetItemInput{
		TableName: &tt.tableName,
		Key:       token.GetKey(),
	})
	if err != nil {
		return "", err
	}

	if err := attributevalue.UnmarshalMap(output.Item, &token); err != nil {
		return "", err
	}
	return token.Token, nil
}

func (tt TokenTable) InsertSFNToken(ctx context.Context, name, token string) error {
	var sfnt SFNToken
	current := time.Now()

	sfnt.Name = name
	sfnt.Token = token
	sfnt.CreatedAt = current

	item, err := attributevalue.MarshalMap(sfnt)
	if err != nil {
		tt.logger.WithField("attribute", item).WithError(err).Error("Marshal PutItem Error")
		return err
	}

	input := dynamodb.PutItemInput{TableName: &tt.tableName, Item: item}
	output, err := tt.db.PutItem(ctx, &input)
	if err != nil {
		tt.logger.WithField("attribute", item).WithError(err).Error("PutItem Error")
		return err
	}
	tt.logger.WithField("output", output).Info("Put Item Success")
	return nil
}
