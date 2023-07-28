const AWS = require('aws-sdk');
const uuid = require('uuid');
const documentClient = new AWS.DynamoDB.DocumentClient();

const createPost = async (args) => {
  const { input } = args;
  const { content, userId, userName } = input;
  const id = uuid.v4();
  const createdAt = new Date().toISOString();

  const params = {
    TableName: 'gatiko-table',
    Item: {
      id: id,
      content: content,
      userId: userId,
      userName: userName,
      createdAt: createdAt,
    },
  };

  try {
    await documentClient.put(params).promise();
    return {
      id: id,
      content: content,
      userId: userId,
      userName: userName,
      createdAt: createdAt,
    };
  } catch (error) {
    console.log('Error:', error);
    throw new Error('Error: Could not create post');
  }
};

const listPosts = async () => {
  const params = {
    TableName: 'gatiko-table',
  };

  try {
    const data = await documentClient.scan(params).promise();
    console.log('Data from DynamoDB:', data);
    return data.Items.map((item) => ({
      id: item.id,
      content: item.content,
      userId: item.userId,
      userName: item.userName,
      createdAt: item.createdAt,
    }));
  } catch (error) {
    console.log('Error:', error);
    throw new Error('Error: Could not list posts');
  }
};

const updatePost = async (args) => {
  const { id, content } = args.input;

  const params = {
    TableName: 'gatiko-table',
    Key: {
      id: id,
    },
    UpdateExpression: 'set content = :c',
    ExpressionAttributeValues: {
      ':c': content,
    },
    ReturnValues: 'ALL_NEW',
  };

  try {
    await documentClient.update(params).promise();
    const readParams = {
      TableName: 'gatiko-table',
      Key: {
        id: id,
      },
    };
    const data = await documentClient.get(readParams).promise();

    return {
      id: data.Item.id,
      content: data.Item.content,
      userId: data.Item.userId,
      userName: data.Item.userName,
      createdAt: data.Item.createdAt,
    };
  } catch (error) {
    console.log('Error:', error);
    throw new Error('Error: Could not update post');
  }
};

const deletePost = async (args) => {
  const { id } = args.input;

  const params = {
    TableName: 'gatiko-table',
    Key: { id },
    ReturnValues: 'ALL_OLD',
  };

  try {
    const deletedPost = await documentClient.delete(params).promise();
    return deletedPost.Attributes;
  } catch (error) {
    console.log('Error:', error);
    throw new Error('Error: Could not delete post');
  }
};

exports.handler = async (event) => {
  console.log('Received event:', event);

  const { field, arguments } = event;

  switch (field) {
    case 'createPost':
      return await createPost(arguments);
    case 'listPosts':
      return await listPosts();
    case 'updatePost':
      return await updatePost(arguments);
    case 'deletePost':
      return await deletePost(arguments);
    default:
      throw new Error('Resolver not found');
  }
};
