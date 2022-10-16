-- PlaylistName:PLUGIN_DYNAMICPLAYLISTS3_BUILTIN_PLAYLIST_SONGS_RATED_EXACTRATING
-- PlaylistGroups:Songs
-- PlaylistCategory:songs
-- PlaylistParameter1:list:PLUGIN_DYNAMICPLAYLISTS3_PARAMNAME_SELECTEXACTRATING:10:0.5,20:1,30:1.5,40:2,50:2.5,60:3,70:3.5,80:4,90:4.5,100:5
-- PlaylistParameter2:list:PLUGIN_DYNAMICPLAYLISTS3_PARAMNAME_INCLUDESONGS:0:PLUGIN_DYNAMICPLAYLISTS3_PARAMVALUENAME_SONGS_ALL,1:PLUGIN_DYNAMICPLAYLISTS3_PARAMVALUENAME_SONGS_UNPLAYED,2:PLUGIN_DYNAMICPLAYLISTS3_PARAMVALUENAME_SONGS_PLAYED
select distinct tracks.url from tracks
	join tracks_persistent on
		tracks_persistent.urlmd5 = tracks.urlmd5 and ifnull(tracks_persistent.rating, 0) = 'PlaylistParameter1'
	left join library_track on
		library_track.track = tracks.id
	left join dynamicplaylist_history on
		dynamicplaylist_history.id=tracks.id and dynamicplaylist_history.client='PlaylistPlayer'
	where
		tracks.audio = 1
		and dynamicplaylist_history.id is null
		and tracks.secs >= 'PlaylistTrackMinDuration'
		and
			case
				when ('PlaylistCurrentVirtualLibraryForClient'!='' and 'PlaylistCurrentVirtualLibraryForClient' is not null)
				then library_track.library = 'PlaylistCurrentVirtualLibraryForClient'
				else 1
			end
		and not exists (select * from tracks t2,genre_track,genres
						where
							t2.id=tracks.id and
							tracks.id=genre_track.track and 
							genre_track.genre=genres.id and
							genres.name in ('PlaylistExcludedGenres'))
		and
			case
				when 'PlaylistParameter2'=1 then ifnull(tracks_persistent.playCount, 0) = 0
				when 'PlaylistParameter2'=2 then ifnull(tracks_persistent.playCount, 0) > 0
				else 1
			end
	group by tracks.id
	order by random()
	limit 'PlaylistLimit';