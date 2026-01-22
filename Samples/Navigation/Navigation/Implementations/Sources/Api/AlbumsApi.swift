// MARK: - Song

public struct Song {
  public let id: String
  public let title: String
  public let author: String
  public let duration: String
}

// MARK: - Album

public struct Album {
  public let id: String
  public let title: String
  public let author: String
  public let dateOfRelease: String
  public let producer: String
  public let songs: [Song]
}

// MARK: - AlbumsResponse

public struct AlbumsResponse {
  public let albums: [Album]
}

// MARK: - AlbumResponse

public struct AlbumResponse {
  public let album: Album
}

// MARK: - SongResponse

public struct SongResponse {
  public let song: Song
}

let fakeSongs: [Song] = [
  Song(id: "0", title: "Regression", author: "John Petrucci", duration: "2:06"),
  Song(id: "1", title: "Overture 1928", author: "Instrumental", duration: "3:37"),
  Song(id: "2", title: "Strange Deja Vu", author: "Mike Portnoy", duration: "5:12"),
  Song(id: "3", title: "Through My Words", author: "John Petrucci", duration: "1:02"),
  Song(id: "4", title: "Fatal Tragedy", author: "John Myung", duration: "6:49"),
  Song(id: "5", title: "Beyond This Life", author: "John Petrucci", duration: "11:22"),
  Song(id: "6", title: "Through Her Eyes", author: "John Petrucci", duration: "5:29"),
  Song(id: "7", title: "Home", author: "Mike Portnoy", duration: "12:53"),
  Song(id: "8", title: "The Dance of Eternity", author: "Instrumental", duration: "6:13"),
  Song(id: "9", title: "One Last Time", author: "James LaBrie", duration: "3:46"),
  Song(id: "10", title: "The Spirit Carries On", author: "John Petrucci", duration: "6:38"),
  Song(id: "11", title: "Finally Free", author: "Mike Portnoy", duration: "11:59"),
  Song(id: "12", title: "Smells Like Teen Spirit", author: "Kurt Cobain", duration: "5:01"),
  Song(id: "13", title: "In Bloom", author: "Dave Grohl", duration: "4:14"),
  Song(id: "14", title: "Come as You Are", author: "Krist Novoselic", duration: "3:39"),
  Song(id: "15", title: "Breed", author: "Kurt Cobain", duration: "3:03"),
  Song(id: "16", title: "Lithium", author: "Kurt Cobain", duration: "4:17"),
  Song(id: "17", title: "Polly", author: "Kurt Cobain", duration: "2:57"),
  Song(id: "18", title: "Overture", author: "Daft punk", duration: "2:28"),
  Song(id: "19", title: "The Grid", author: "Daft punk", duration: "1:36"),
  Song(id: "20", title: "The Son of Flynn", author: "Daft punk", duration: "1:35"),
  Song(id: "21", title: "Recognizer", author: "Daft punk", duration: "2:37"),
  Song(id: "22", title: "Armory", author: "Daft punk", duration: "2:03"),
  Song(id: "23", title: "Arena", author: "Daft punk", duration: "1:33"),
  Song(id: "24", title: "Rinzler", author: "Daft punk", duration: "2:17"),
  Song(id: "25", title: "The Game Has Changed", author: "Daft punk", duration: "3:25"),
  Song(id: "26", title: "Outlands", author: "Daft punk", duration: "2:42"),
  Song(id: "27", title: "Adagio For TRON", author: "Daft punk", duration: "4:11")
]

let fakeAlbums: [Album] = [
  Album(
    id: "0",
    title: "Scenes from a memory",
    author: "Dream Theater",
    dateOfRelease: "1999, Oct 26",
    producer: "Portnoy & Petrucci",
    songs: Array(fakeSongs[0...11])
  ),
  Album(
    id: "1",
    title: "Nevermind",
    author: "Nirvana",
    dateOfRelease: "1991, Sept 24",
    producer: "Butch Vig",
    songs: Array(fakeSongs[12...17])
  ),
  Album(
    id: "2",
    title: "Tron: Legacy",
    author: "Daft punk",
    dateOfRelease: "2010, Dec 10",
    producer: "Daft punk",
    songs: Array(fakeSongs[18...27])
  )
]

public func fetchAlbums() async throws -> AlbumsResponse {
  try await Task.sleep(for: .seconds(1))
  return AlbumsResponse(albums: fakeAlbums)
}

public func fetchAlbum(id: String) async throws -> AlbumResponse {
  try await Task.sleep(for: .seconds(1))
  let album = fakeAlbums.first(where: { $0.id == id })
  return AlbumResponse(album: album!)
}

public func fetchSong(id: String) async throws -> SongResponse {
  try await Task.sleep(for: .seconds(1))
  let song = fakeSongs.first(where: { $0.id == id })
  return SongResponse(song: song!)
}
