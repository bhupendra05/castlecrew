const functions = require("firebase-functions");
const admin=require("firebase-admin");
const { user } = require("firebase-functions/v1/auth");
admin.initializeApp();
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
exports.onCreateFollower=functions.firestore.document("/followers/{userId}/userFollowers/{followerId}")
.onCreate(async(snapshot,context)=>{
    console.log("follower created",snapshot.id);
    const userId=context.params.userId;
    const followerId=context.params.followerId;

    const followedUserPostsRef=admin.firestore().collection('posts').doc(userId).collection('userPosts');


    const timelinePostsRef=admin.firestore().collection('timeline').doc(followerId).collection('timelinePosts');

    const querySnapshot=await followedUserPostsRef.get();

    querySnapshot.forEach(doc=>{
        if(doc.exists){
            const postId=doc.id;
            const postData=doc.data();
            timelinePostsRef.doc(postId).set(postData);
        }
    });
});

exports.onDeleteFollower=functions.firestore.document("/followers/{userId}/userFollowers/{followerId}").onDelete(async(snapshot,context)=>{
    console.log("Follower Deleted",snapshot.id);

const userId=context.params.userId;
const followerId=context.params.followerId;

const timelinePostsRef=admin.firestore().collection("timeline").doc(followerId).collection("timelinePosts").where("ownerId","==",userId);

const querySnapshot=await timelinePostsRef.get();
querySnapshot.forEach(doc=>{
    if(doc.exists){
        doc.ref.delete();
    }
});

});

// when a post is created , add post to timeline of each follower(of post owner).

exports.onCreatePost=functions.firestore.document('/posts/{userId}/userPosts/{postId}')
.onCreate(async(snapshot,context)=>{
const postCreated=snapshot.data();
const userId=context.params.userId;
const postId= context.params.postId;
//1.get all the followers of the user who made the post.

const userFollowersRef=admin.firestore().collection('followers').doc(userId).collection('userFollowers');
const querySnapshot =await userFollowersRef.get();

//2.add new post to each followers timeline.
querySnapshot.forEach(doc=>{
    const followerId=doc.id;
    admin.firestore().collection('timeline').doc(followerId).collection('timelinePosts').doc(postId).set(postCreated);
});


});

exports.onUpdatePost=functions.firestore.document('/posts/{userId}/userPosts/{postId}')
.onUpdate(async(change,context)=>{
const postUpdated=change.after.data();
const userId=context.params.userId;
const postId= context.params.postId;
//1.get all the followers of the user who made the post.

const userFollowersRef=admin.firestore().collection('followers').doc(userId).collection('userFollowers');
const querySnapshot =await userFollowersRef.get();

//2.Update each post in each followers timeline.
querySnapshot.forEach(doc=>{
    const followerId=doc.id;
    admin.firestore().collection('timeline').doc(followerId).collection('timelinePosts').doc(postId)
    .get().then(doc=>{
        if(doc.exists){
            doc.ref.update(postUpdated);
        }
    });
});


});

exports.onDeletePost=functions.firestore.document('/posts/{userId}/userPosts/{postId}')
.onDelete(async(snapshot,context)=>{
const userId=context.params.userId;
const postId= context.params.postId;
//1.get all the followers of the user who made the post.

const userFollowersRef=admin.firestore().collection('followers').doc(userId).collection('userFollowers');
const querySnapshot =await userFollowersRef.get();

//2.Delete each post in each followers timeline.
querySnapshot.forEach(doc=>{
    const followerId=doc.id;
    admin.firestore().collection('timeline').doc(followerId).collection('timelinePosts').doc(postId)
    .get().then(doc=>{
        if(doc.exists){
            doc.ref.delete();
        }
    });
});


});

