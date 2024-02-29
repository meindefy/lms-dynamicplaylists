-- PlaylistName:PLUGIN_DYNAMICPLAYLISTS4_BUILTIN_PLAYLIST_ALBUMS_PARTLYPLAYED_GENRE_DECADE_APC
-- PlaylistGroups:Albums
-- PlaylistCategory:albums
-- PlaylistTrackOrder:ordered
-- PlaylistLimitOption:unlimited
-- PlaylistParameter1:list:PLUGIN_DYNAMICPLAYLISTS4_PARAMNAME_INCLUDECOMPIS:0:PLUGIN_DYNAMICPLAYLISTS4_PARAMVALUENAME_ALBUMS_ALL,1:PLUGIN_DYNAMICPLAYLISTS4_PARAMVALUENAME_ALBUMS_COMPISONLY,2:PLUGIN_DYNAMICPLAYLISTS4_PARAMVALUENAME_ALBUMS_NOCOMPIS
-- PlaylistParameter2:multiplegenres:PLUGIN_DYNAMICPLAYLISTS4_PARAMNAME_SELECTGENRES:
-- PlaylistParameter3:multipledecades:PLUGIN_DYNAMICPLAYLISTS4_PARAMNAME_SELECTDECADES:
drop table if exists dynamicplaylist_random_albums;
create temporary table dynamicplaylist_random_albums as
	select tracks.album as album, count(distinct tracks.id) as totaltrackcount from tracks
		join albums on
			albums.id = tracks.album
		join genre_track on
			genre_track.track = tracks.id and genre_track.genre in ('PlaylistParameter2')
		join alternativeplaycount on
			alternativeplaycount.urlmd5 = tracks.urlmd5
		left join library_track on
			library_track.track = tracks.id
		left join dynamicplaylist_history on
			dynamicplaylist_history.id = tracks.id and dynamicplaylist_history.client = 'PlaylistPlayer'
		where
			tracks.audio = 1
			and dynamicplaylist_history.id is null
			and
				case
					when ('PlaylistCurrentVirtualLibraryForClient' != '' and 'PlaylistCurrentVirtualLibraryForClient' is not null)
					then library_track.library = 'PlaylistCurrentVirtualLibraryForClient'
					else 1
				end
			and not exists (select * from tracks t2, genre_track, genres
							where
								t2.id = tracks.id and
								tracks.id = genre_track.track and
								genre_track.genre = genres.id and
								genres.namesearch in ('PlaylistExcludedGenres'))
		group by tracks.album
			having totaltrackcount >= 'PlaylistMinAlbumTracks'
			and min(ifnull(alternativeplaycount.playCount,0)) = 0 and avg(ifnull(alternativeplaycount.playCount,0)) > 0
			and ifnull(albums.year, 0) in ('PlaylistParameter3')
			and
				case
					when 'PlaylistParameter1' = 1 then ifnull(albums.compilation, 0) = 1
					when 'PlaylistParameter1' = 2 then ifnull(albums.compilation, 0) = 0
					else 1
				end
		order by random()
		limit 1;
select tracks.id, tracks.primary_artist from tracks
	join dynamicplaylist_random_albums on
		dynamicplaylist_random_albums.album = tracks.album
	join genre_track on
		genre_track.track = tracks.id and genre_track.genre in ('PlaylistParameter2')
	left join library_track on
		library_track.track = tracks.id
	left join dynamicplaylist_history on
		dynamicplaylist_history.id = tracks.id and dynamicplaylist_history.client = 'PlaylistPlayer'
	where
		tracks.audio = 1
		and tracks.secs >= 'PlaylistTrackMinDuration'
		and dynamicplaylist_history.id is null
		and
			case
				when ('PlaylistCurrentVirtualLibraryForClient' != '' and 'PlaylistCurrentVirtualLibraryForClient' is not null)
				then library_track.library = 'PlaylistCurrentVirtualLibraryForClient'
				else 1
			end
		and not exists (select * from tracks t2, genre_track, genres
						where
							t2.id = tracks.id and
							tracks.id = genre_track.track and
							genre_track.genre = genres.id and
							genres.namesearch in ('PlaylistExcludedGenres'))
	group by tracks.id
	order by dynamicplaylist_random_albums.album,tracks.disc,tracks.tracknum
	limit 'PlaylistLimit';
drop table dynamicplaylist_random_albums;
