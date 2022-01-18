<template>
  <div v-if="fetching">
    Loading...
  </div>
  <div v-else-if="error">
    Oh no... {{ error }}
  </div>

  <div v-else>
    <el-table
      :data="data.allFolders.nodes"
      :v-if="data.allFolders?.nodes"
      fit
      size="large"
      style="width: 100%"
      row-key="id"
      default-expand-all
    >
      <el-table-column>
        <template #header>
          <el-input v-model="newFolder" v-if="canCreateFolder" placeholder="Folder name" />
        </template>
        <template #default="scope">
          <el-input v-model="documentName" v-if="scope.row.createFile" placeholder="Document name" />
          <el-icon v-else>
            <Folder v-if="scope.row.__typename==='Folder'"></Folder>
            <Document v-else />
          </el-icon>
          <span  v-if="!scope.row.createFile" style="margin-left: 10px">{{ scope.row.name }}</span>
        </template>
      </el-table-column>
      <el-table-column fixed="right" width="200">
        <template #header>
          <el-button-group v-if="canCreateFolder" size="small">
            <el-button type="success" @click="createFolder" plain :icon="Check"></el-button>
            <el-button type="danger" @click="canCreateFolder=false" plain :icon="Close"></el-button>
          </el-button-group>
          <el-button v-else @click="canCreateFolder=true" size="small" :icon="FolderAdd"></el-button>
        </template>
        <template #default="scope">
          {{ consoleLog(scope) }}
          <el-button-group v-if="scope.row.createFile" size="small">
            <el-button type="success" @click="createDocument(scope.row.id)"  plain :icon="Check"></el-button>
            <el-button type="danger" @click="scope.row.createFile=false" plain :icon="Close"></el-button>
          </el-button-group>
          <el-button-group size="small" v-else-if="scope.row.__typename==='Folder'">
            <el-button :icon="Edit"></el-button>
            <el-button :icon="DocumentAdd" @click="scope.row.createFile=true"></el-button>
            <el-button :icon="Delete"></el-button>
          </el-button-group>
          <el-button-group size="small" v-else>
            <router-link :to="{ name: 'document', params: { documentId: scope.row.id }}"  custom
                         v-slot="{ navigate }">
              <el-button @click="navigate" :icon="Edit"></el-button>
            </router-link>

            <el-button :icon="Delete"></el-button>
          </el-button-group>
        </template>
      </el-table-column>
    </el-table>
  </div>


</template>

<script setup>
import { ref } from "vue";
// import { ElMessageBox } from 'element-plus'
import { Folder, Document, Edit, Delete, DocumentAdd, FolderAdd, Check, Close } from "@element-plus/icons-vue";
import { useMutation, useQuery } from "@urql/vue";
import { useRoute } from 'vue-router'

const getFolders = `query userDocumentsByFolders($groupId: UUID!) {
  allFolders(filter: {groupId: {equalTo: $groupId}}) {
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
`;
const folder = `
mutation createFolder($groupId: UUID!, $folderName: String!) {
  createFolder(input: { folder: { groupId: $groupId name: $folderName } }) {
    folder {
      id
    }
  }
}
`;
const document = `
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
`;
const updateFolder = useMutation(folder);
const updateDocument = useMutation(document);


// const data = ref([]);
const newFolder = ref("");
const documentName = ref("");
const route = useRoute()
const canCreateFolder = ref(false);

// const fetching = ref(true);

function consoleLog(a) {
  console.log("---", a);
}

// const updateGroup = useMutation(createGroup);

const foldersResult = useQuery({
  query: getFolders,
  variables: { groupId:route.params.groupId }
});

const createFolder = async () => {
  const result = await updateFolder.executeMutation({ folderName: newFolder.value ,groupId:'ff70e079-0d69-4462-a549-07cb470e0713'});
  if (result.error) {
    console.log("---", result.error);
  } else {
    canCreateFolder.value = false;
    foldersResult.executeQuery({
      requestPolicy: "network-only"
    });
  }
};
const createDocument = async (id) => {
  const result = await updateDocument.executeMutation({ folderId: id , ownerId: 'd9baed9a-5bba-4a8f-9c6a-e348a1f6f3c7', documentName:documentName.value});
  if (result.error) {
    console.log("---", result.error);
  } else {
    canCreateFolder.value = false;
    foldersResult.executeQuery({
      requestPolicy: "network-only"
    });
  }
};

const fetching = foldersResult.fetching;
const data = foldersResult.data;
const error = foldersResult.error;


</script>

<style scoped>
.el-input {
  width: 90%;
}

.el-tag {
  margin-right: 15px;
}
</style>
