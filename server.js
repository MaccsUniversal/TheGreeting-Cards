const express = require('express');
const cors = require('cors');
const ImageKit = require('imagekit');
const { response, request } = require('express');
// const upload = multer({dest: '/uploads'})
const https = require('https');
const app = express();
require('dotenv').config({path: './IMAGEKIT_KEYS.env'});
const PORT = 3000;
// Requiring file system to use local files
const fs = require("fs");

app.use(express.json({limit: '1mb'}));
app.use(cors());

var imagekit = new ImageKit({
    publicKey : process.env.IMAGEKIT_PUBLIC_KEY,
    privateKey : process.env.IMAGEKIT_PRIVATE_KEY,
    urlEndpoint : "https://ik.imagekit.io/thegivingkind2021"
});

app.get('/uploadImages', function(req, res) {
    res.setHeader("Access-Control-Allow-Origin", "http://localhost:3000");
    var authenticationParameters = imagekit.getAuthenticationParameters();
    res.send(authenticationParameters);
})

app.post('/deleteImage',function(req,res){
    res.setHeader("Access-Control-Allow-Origin", "http://localhost:3000");
    var fileId = req.body.fileId;
    imagekit.deleteFile(fileId, function(error, result) {
        if(!error){
            res.send({
                status: "success",
                result: result,
                message: "Your image will NOT been stored until all transactions are completed successfully."
            })
        } else {
            res.send({
                status: "failed",
                result: error,
                message: "Your image has been stored although the transactions have failed. Please contact our team to have your image deleted."
            })
        }
    })

})

// Creating object of key and certificate
// for SSL
// const options = {
//     key: fs.readFileSync("server.key"),
//     cert: fs.readFileSync("server.cert"),
//   };

// https.createServer(options, app)
// .listen(PORT, function (err) {
//     if(err){
//         console.log(err);
//     } else {
//         console.log("Server started at port " + PORT + "...");
//     }
// });


// Creating https server by passing
// options and app object
// https.createServer(options, app)
// .listen(PORT, function (req, res) {
//   console.log("Server started at port " + PORT);
// });

let server = app.listen(PORT, function (err) {
    if(err){
        console.log(err);
    } else {
        console.log("Listening on port " + PORT + "...");
    }
});



// app.use(cors());