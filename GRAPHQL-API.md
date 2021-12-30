# GraphQL

## Mutations

### Registration

```
mutation register($username: String!, $password: String!) {
  register(input: {username: $username, password: $password}) {
    user {
      id
    }
  }
}
```


### Authorization and Authentication

```
mutation authenticate($username: String!, $password: String!) {
  authenticate(input: {username: $username, password: $password}) {
    jwtToken
  }
}
```

You should extract `jwtToken` from the response payload and send it via `Authorization` header ([example](https://www.graphile.org/postgraphile/security/#sending-jwts-to-the-server)):

```
Authorization: Bearer jwtToken
```

### Create new group

```
mutation createGroup($userId: UUID!, $groupName: String!) {
  addGroup(input: {userId: $userId, name: $groupName}) {
    results {
      groupId
      groupName
    }
  }
}
```

### Create new folder

```
mutation createFolder($groupId: UUID!, $folderName: String!) {
  createFolder(input: { folder: { groupId: $groupId name: $folderName } }) {
    folder {
      id
    }
  }
}
```

### Create new document

```
mutation createDocument($folderId: UUID!, $ownerId: UUID!, $documentName: String!, $documentBody: String) {
  createDocument(
    input: {document: { folderId: $folderId, ownerId: $ownerId, name: $documentName, body: $documentBody }}
  ) {
    document {
      id
      ownerId
      name
      body
    }
  }
}
```

## Queries

### Get User info

```
query allUsers {
  allUsers {
    nodes {
      id
      username
      createdAt
      updatedAt
    }
  }
}
```

### Get User Groups

```
query userGroups {
  allMemberships {
    nodes {
      groupByGroupId {
        id
        name
      }
    }
  }
}
```

### Get User Folders by Groups

```
query userFoldersByGroups {
  allGroups {
    nodes {
    	id
    	name
      foldersByGroupId {
        nodes {
          id
          name
        }
      }
    }
  }
}
```

### Get User Documents

```
query userDocumentsByFolders {
  allFolders {
    nodes {
      id
      name
      documentsByFolderId {
        nodes {
          id
          name
          body
        }
      }
    }
  }
}
```