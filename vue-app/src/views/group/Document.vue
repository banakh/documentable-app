<template>
  <div v-if="fetching">
    Loading...
  </div>
  <div v-else-if="error">
    Oh no... {{ error }}
  </div>
  <div v-else>
    <el-page-header content="detail" @back="goBack" />
    <v-ace-editor
      v-model:value="data.documentById.body"
      lang="markdown"
      @init="editorInit"
      theme="chrome"
      style="height: 300px; margin: 20px" />
    <el-button  @click="updateDocument(data.documentById.body)" plain>Save</el-button>
  </div>
</template>

<script setup>
import { VAceEditor } from 'vue3-ace-editor';
import "ace-builds/webpack-resolver";
import { useMutation, useQuery } from "@urql/vue";
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'

const documentMut = `
mutation updateDocumentMutation($documentBody: String, $documentId: UUID!) {
  updateDocumentById(input: {documentPatch: {body: $documentBody}, id: $documentId}){
  document {
      name
      ownerId
      updatedAt
      id
      createdAt
      body
    }
  }
}
`;

const document = `query MyQuery($documentId: UUID!) {
  documentById(id: $documentId) {
    name
    ownerId
    id
    folderId
    body
  }
}
`;

const goBack = () => {
  console.log('go back')
}

const updateDocumentMutation = useMutation(documentMut);

function editorInit () {
}

// const data = ref([]);

const route = useRoute()

// const fetching = ref(true);


// const updateGroup = useMutation(createGroup);

const documentResult = useQuery({
  query: document,
  variables: { documentId:route.params.documentId }
});


const updateDocument = async (body) => {
  const result = await updateDocumentMutation.executeMutation({ documentId: route.params.documentId , documentBody:body});
  if (result.error) {
    console.log("---", result.error);
  } else {
    ElMessage({
      showClose: true,
      message: 'Congrats, this is a success message.',
      type: 'success',
    })
    documentResult.executeQuery({
      requestPolicy: "network-only"
    });
  }
};

const fetching = documentResult.fetching;
const data = documentResult.data;
const error = documentResult.error;


</script>

<style>
.el-input {
  width: 90%;
}

.el-tag {
  margin-right: 15px;
}
</style>
