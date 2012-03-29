
/*
* soundscrape
* Dan Motzenbecker
*/

(function() {
  var argLen, artist, download, fs, http, page, parse, rootHost, scrape, trackName;

  http = require('http');

  fs = require('fs');

  rootHost = 'soundcloud.com';

  page = 1;

  argLen = process.argv.length;

  scrape = function() {
    return http.get({
      host: rootHost,
      path: '/' + artist + '/' + (typeof trackName !== "undefined" && trackName !== null ? trackName : 'tracks?page=' + page)
    }, function(res) {
      var data;
      data = '';
      res.on('data', function(chunk) {
        return data += chunk;
      });
      return res.on('end', function() {
        var track, tracks, _i, _len;
        tracks = data.match(/(window\.SC\.bufferTracks\.push\().+(?=\);)/gi);
        if (typeof trackName !== "undefined" && trackName !== null) {
          download(parse(tracks[0]));
          return console.log('');
        } else {
          for (_i = 0, _len = tracks.length; _i < _len; _i++) {
            track = tracks[_i];
            download(parse(track));
          }
          if (tracks.length === 10) {
            page++;
            return scrape();
          } else {
            return console.log('');
          }
        }
      });
    });
  };

  parse = function(raw) {
    return JSON.parse(raw.substr(28));
  };

  download = function(obj) {
    var artist, title;
    artist = obj.user.username;
    title = obj.title;
    console.log('\x1b[33mfetching: ' + title + '\x1b[0m');
    return http.get({
      host: 'media.' + rootHost,
      path: obj.streamUrl.match(/\/stream\/.+/)
    }, function(res) {
      return res.on('end', function() {
        return http.get({
          host: 'ak-media.' + rootHost,
          path: res.headers.location.substr(30)
        }, function(res) {
          var file;
          file = fs.createWriteStream('./' + artist + ' - ' + title + '.mp3');
          res.on('data', function(chunk) {
            return file.write(chunk);
          });
          return res.on('end', function() {
            file.end();
            return console.log('\x1b[32mdone:     ' + title + '\x1b[0m');
          });
        });
      });
    });
  };

  if (argLen < 2) return console.log('pass an artist name!');

  artist = process.argv[2];

  if (argLen > 3) trackName = process.argv[3];

  scrape();

}).call(this);
