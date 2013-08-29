request = require 'request'
querystring = require 'querystring'

module.exports = (app) ->
	class app.YouTube

		API_KEY = "AIzaSyDVTGYt3PThnKmbhDQzccy0FcH5-Z-zkT8"

		@signatureDecipher =
			timestamp: 15902,

			clone: (a, b) ->
				a.slice(b)

			decipher: (s) ->
		    t = s.split ""
		    t = @clone t, 2
		    t = @reverse t
		    t = @clone t, 3
		    t = @swap t, 9
		    t = @clone t, 3
		    t = @swap t, 43
		    t = @clone t, 3
		    t = @reverse t
		    t = @swap t, 23
		    t.join ""

			swap: (a, b) ->
		    t1 = a[0]
		    t2 = a[(b % a.length)]
		    a[0] = t2
		    a[b] = t1
		    return a

			reverse: (a) ->
			  a.reverse()
			  return a

		@processVideoInfo = (text) ->
			info = {}

			data = querystring.parse text

			if data.errorcode
				info.error = data.reason
				return info

			# Format Reference

			# 5 - FLV 240p
			# 18 - MP4 360p
			# 22 - MP4 720p (HD)
			# 34 - FLV 360p
			# 35 - FLV 480p
			# 37 - MP4 1080p (HD)
			# 38 - MP4 Original (HD)
			# 43 - WebM 480p
			# 45 - WebM 720p (HD)

			youtubeFormats = { 18: '360p', 22: '720p', 37: '1080p', 38: 'Original (4k)' }

			defaultFormat = '720p'

			info.formats = {}
			for format in data.url_encoded_fmt_stream_map.split(',')
				tmp = querystring.parse format
				if youtubeFormats[tmp.itag]
					url = tmp.url #+ '&title=' + encodeURIComponent(data.title)
					if tmp.sig
						url += '&signature=' + encodeURIComponent(tmp.sig)
					else if tmp.s
						url += '&signature=' + encodeURIComponent(@signatureDecipher.decipher(tmp.s))
					info.formats[youtubeFormats[tmp.itag]] = url

			if info.formats['720p']
				info.useFormat = '720p'
			else
				info.useFormat = '360p'

			if data.iurlmaxres
				info.poster = data.iurlmaxres
			else if data.iurlsd
				info.poster = data.iurlsd
			else if data.thumbnail_url
				info.poster = data.thumbnail_url.replace(/default.jpg/, 'hqdefault.jpg')

			info.title = data.title
			info.author = data.author
			info.authorLink = 'https://www.youtube.com/user/' + data.author
			info.link = 'https://www.youtube.com/watch?v=' + data.video_id

			return info

		@getVideoInfo = (videoId, callback) =>
			request {url: "https://www.youtube.com/get_video_info?&video_id=#{videoId}&eurl=http%3A%2F%2Fwww%2Eyoutube%2Ecom%2F&asv=3&sts=#{@signatureDecipher.timestamp}", headers: { 'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/537.59 (KHTML, like Gecko) Version/6.1 Safari/537.59' }}, (err, response, body) =>
				return callback err if err

				info = @processVideoInfo body
				if info.error
					callback info.error
				else
					callback null, info

		@search = (q, callback) =>
			request "https://www.googleapis.com/youtube/v3/search?key=#{API_KEY}&maxResults=20&part=id&q=#{encodeURIComponent(q)}", (err, response, body) =>
				return callback err if err

				results = JSON.parse body

				videoIds = (item.id.videoId for item in results.items when item.id.kind == "youtube#video").join ','

				request "https://www.googleapis.com/youtube/v3/videos?key=#{API_KEY}&part=snippet%2CcontentDetails%2Cstatistics&id=#{encodeURIComponent(videoIds)}", (err, response, body) =>
					callback null, JSON.parse(body)

