-- PlaylistName:PLUGIN_DYNAMICPLAYLISTS4_BUILTIN_PLAYLIST_CONTEXT_ALBUM_SONGS_PLAYEDLONGAGO_APC
-- PlaylistGroups:Context menu lists/ album
-- PlaylistMenuListType:contextmenu
-- PlaylistCategory:albums
-- PlaylistUseCache: 1
-- PlaylistParameter1:album:PLUGIN_DYNAMICPLAYLISTS4_PARAMNAME_SELECTALBUM:
-- PlaylistParameter2:list:PLUGIN_DYNAMICPLAYLISTS4_PARAMNAME_INCLUDESONGS:0:PLUGIN_DYNAMICPLAYLISTS4_PARAMVALUENAME_SONGS_ALL,1:PLUGIN_DYNAMICPLAYLISTS4_PARAMVALUENAME_SONGS_UNPLAYED,2:PLUGIN_DYNAMICPLAYLISTS4_PARAMVALUENAME_SONGS_PLAYED
select tracks.id, tracks.primary_artist from tracks
	left join library_track on
		library_track.track = tracks.id
	join alternativeplaycount on
		alternativeplaycount.urlmd5 = tracks.urlmd5 and ((strftime('%s',DATE('NOW','-'PlaylistPeriodPlayedLongAgo' YEAR'))-ifnull(alternativeplaycount.lastPlayed,0)) > 0)
	left join dynamicplaylist_history on
		dynamicplaylist_history.id = tracks.id and dynamicplaylist_history.client = 'PlaylistPlayer'
	where
		tracks.audio = 1
		and tracks.album = 'PlaylistParameter1'
		and tracks.secs >= 'PlaylistTrackMinDuration'
		and dynamicplaylist_history.id is null
		and
			case
				when 'PlaylistParameter2' = 1 then ifnull(alternativeplaycount.playCount, 0) = 0
				when 'PlaylistParameter2' = 2 then ifnull(alternativeplaycount.playCount, 0) > 0
				else 1
			end
		and
			case
				when ('PlaylistCurrentVirtualLibraryForClient' != '' and 'PlaylistCurrentVirtualLibraryForClient' is not null)
				then library_track.library = 'PlaylistCurrentVirtualLibraryForClient'
				else 1
			end
		and not exists (select * from tracks t2,genre_track,genres
						where
							t2.id = tracks.id and
							tracks.id = genre_track.track and
							genre_track.genre = genres.id and
							genres.namesearch in ('PlaylistExcludedGenres'))
	group by tracks.id
