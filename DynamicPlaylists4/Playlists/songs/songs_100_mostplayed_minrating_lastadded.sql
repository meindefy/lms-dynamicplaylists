-- PlaylistName:PLUGIN_DYNAMICPLAYLISTS4_BUILTIN_PLAYLIST_SONGS_MOSTPLAYED_MINRATING
-- PlaylistGroups:Songs
-- PlaylistCategory:songs
-- PlaylistUseCache: 1
-- PlaylistTrackOrder:ordereddescrandom
-- PlaylistAPCdupe:yes
-- PlaylistParameter1:list:PLUGIN_DYNAMICPLAYLISTS4_PARAMNAME_SELECTMINRATING:0:PLUGIN_DYNAMICPLAYLISTS4_PARAMVALUENAME_UNRATED,20:*,40:**,60:***,80:****,100:*****
-- PlaylistParameter2:list:PLUGIN_DYNAMICPLAYLISTS4_PARAMNAME_SELECTLASTADDEDPERIOD_SONGS:0:PLUGIN_DYNAMICPLAYLISTS4_PARAMVALUENAME_SELECTLASTADDEDPERIOD_ALL,604800:PLUGIN_DYNAMICPLAYLISTS4_PARAMVALUENAME_SELECTLASTADDEDPERIOD_1WEEK,1209600:PLUGIN_DYNAMICPLAYLISTS4_PARAMVALUENAME_SELECTLASTADDEDPERIOD_2WEEKS,2419200:PLUGIN_DYNAMICPLAYLISTS4_PARAMVALUENAME_SELECTLASTADDEDPERIOD_4WEEKS,7257600:PLUGIN_DYNAMICPLAYLISTS4_PARAMVALUENAME_SELECTLASTADDEDPERIOD_3MONTHS,14515200:PLUGIN_DYNAMICPLAYLISTS4_PARAMVALUENAME_SELECTLASTADDEDPERIOD_6MONTHS,29030399:PLUGIN_DYNAMICPLAYLISTS4_PARAMVALUENAME_SELECTLASTADDEDPERIOD_12MONTHS
select tracks.id, tracks.primary_artist, tracks_persistent.playCount from tracks
	left join library_track on
		library_track.track = tracks.id
	join tracks_persistent on
		tracks_persistent.urlmd5 = tracks.urlmd5 and ifnull(tracks_persistent.rating, 0) >= 'PlaylistParameter1'
	left join dynamicplaylist_history on
		dynamicplaylist_history.id = tracks.id and dynamicplaylist_history.client = 'PlaylistPlayer'
	where
		tracks.audio = 1
		and dynamicplaylist_history.id is null
		and tracks.secs >= 'PlaylistTrackMinDuration'
		and
			case
				when 'PlaylistParameter2'>0 then (tracks_persistent.added >= (select max(ifnull(tracks_persistent.added,0)) from tracks_persistent) - 'PlaylistParameter2')
				else 1
			end
		and not exists (select * from tracks t2,genre_track,genres
						where
							t2.id = tracks.id and
							tracks.id = genre_track.track and
							genre_track.genre = genres.id and
							genres.namesearch in ('PlaylistExcludedGenres'))
		and
			case
				when ('PlaylistCurrentVirtualLibraryForClient' != '' and 'PlaylistCurrentVirtualLibraryForClient' is not null)
				then library_track.library = 'PlaylistCurrentVirtualLibraryForClient'
				else 1
			end
	group by tracks.id
	order by tracks_persistent.playCount desc, random()
