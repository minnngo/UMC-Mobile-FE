import '../../models/movie.dart';
import '../../models/movie_detail.dart';

/// W3-02 영화 목록 Figma 기준 Mock 데이터입니다.
/// posterAsset은 목록 카드(2:3)용 세로 포스터입니다.
const movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2023,
    rating: 4.8,
    posterAsset: 'assets/images/posters/card_us_under_the_starlight.png',
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    rating: 4.2,
    posterAsset: 'assets/images/posters/card_echoes_of_the_void.png',
  ),
  Movie(
    id: 3,
    title: '기억의 숲',
    genre: '애니메이션',
    year: 2022,
    rating: 4.9,
    posterAsset: 'assets/images/posters/card_whispering_woods.png',
  ),
  Movie(
    id: 4,
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    rating: 3.8,
    posterAsset: 'assets/images/posters/card_night_shadows.png',
  ),
  Movie(
    id: 5,
    title: '봄날의 커피',
    genre: '로맨스',
    year: 2021,
    rating: 4.5,
    posterAsset: 'assets/images/posters/card_fourth_afternoon.png',
  ),
  Movie(
    id: 6,
    title: '도시의 선',
    genre: '다큐멘터리',
    year: 2023,
    rating: 4.1,
    posterAsset: 'assets/images/posters/card_city_rhythm.png',
  ),
];

/// 홈 '인기 영화' 섹션 Mock 데이터 (W3-01 Figma) — 순위는 목록 순서(1부터)
/// Figma 홈 카드는 10점 만점(9.6)으로 표시하므로 평점은 5점 만점 값으로 저장하고 화면에서 x2 합니다.
/// 장르·연도는 Figma에 없어 임의의 Mock 값입니다.
const popularMovies = [
  // 에셋 팩의 poster_abyss_walker.jpg는 이름과 달리 MISSION: IMPROBABLE 이미지라
  // Figma에서 내보낸 ABYSS WALKER 포스터를 사용합니다.
  Movie(
    id: 7,
    title: '마션 레스큐',
    genre: 'SF',
    year: 2024,
    rating: 4.8,
    posterAsset: 'assets/images/posters/poster_martian_rescue.png',
  ),
  Movie(
    id: 8,
    title: '스파이 코드',
    genre: '액션',
    year: 2024,
    rating: 4.6,
    posterAsset: 'assets/images/posters/poster_spy_code.png',
  ),
  // TODO: 포스터가 화면에 보이는 부분(76 x 200)만 잘린 이미지라 전체 이미지로 교체 필요
  Movie(
    id: 9,
    title: '비오는 날의 기억',
    genre: '드라마',
    year: 2023,
    rating: 4.45,
    posterAsset: 'assets/images/posters/poster_rainy_day.jpg',
  ),
];

/// 영화 목록·홈 인기 영화 어디에서 눌러도 같은 ID로 찾을 수 있습니다.
Movie? findMovieById(int? id) {
  for (final movie in [...movies, ...popularMovies]) {
    if (movie.id == id) return movie;
  }
  return null;
}

/// Figma W3-03 기준 상세 내용 (영화 id → 상세)
const _movieDetails = {
  1: MovieDetail(
    title: '별빛 아래 우리',
    heroAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
    year: 2024,
    genres: ['로맨스', '드라마'],
    runtimeMinutes: 124,
    rating: 4.5,
    reviewCount: 1245,
    tags: ['로맨스', '드라마', '감동적인'],
    synopsis: [
      '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 '
          '작은 천문대에서 만나게 됩니다. 매일 밤 별을 관측하며 서로의 상처를 치유하고, '
          '잊고 있던 꿈과 사랑을 다시금 깨닫게 되는 따뜻한 이야기입니다.',
      '과거의 아픔으로 인해 사람에게 마음을 열지 못하던 여주인공은, 별자리처럼 변함없는 '
          '모습으로 자신을 기다려주는 남주인공을 통해 서서히 마음의 문을 열게 됩니다. '
          '하지만 두 사람 앞에 놓인 현실적인 장벽들은 그들의 관계를 시험하게 되는데...',
      '별이 쏟아지는 밤하늘 아래, 그들이 나눈 조용한 약속들은 과연 영원할 수 있을까요? '
          '눈부신 영상미와 감성적인 OST가 어우러져 깊은 여운을 남기는 올 겨울 최고의 로맨스 영화.',
      '잔잔한 감동과 함께 삶의 의미를 다시 한번 되돌아보게 만드는 수작입니다.',
    ],
  ),
};

/// 영화 id로 상세 정보를 찾습니다. 없는 영화면 null입니다.
MovieDetail? findMovieDetailById(int? id) {
  final movie = findMovieById(id);
  if (movie == null) return null;
  return _movieDetails[movie.id] ?? MovieDetail.fromMovie(movie);
}
