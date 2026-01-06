<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\UserController;
use App\Http\Controllers\RegionController;
use App\Http\Controllers\ProvinceController;
use App\Http\Controllers\CityController;
use App\Http\Controllers\LeaderboardController;
use App\Http\Controllers\QuizController;
use App\Http\Controllers\GameController;
use App\Http\Controllers\FastestTimeController;
use App\Http\Controllers\BadgeController;
use App\Http\Controllers\StarsController;

// ==========================================
// AUTH & USER
// ==========================================
Route::post('/user/register', [UserController::class, 'register']);
Route::post('/login', [UserController::class, 'login']);
Route::get('/user/profile/{id}', [UserController::class, 'profile']);
Route::put('/user/update/{id}', [UserController::class, 'update']);
Route::get('/homepage/{id}', [UserController::class, 'homepage']);
Route::put('/user/change-password/{id}', [UserController::class, 'changePassword']);
Route::post('/user/logout', [UserController::class, 'logout']);
// ==========================================
// LOCATION
// ==========================================
Route::get('/region', [RegionController::class, 'index']);
Route::get('/province/{regionId}', [ProvinceController::class, 'getByRegion']);
Route::get('/city/{provinceId}', [CityController::class, 'getByProvince']);

// ==========================================
// QUIZ QUESTIONS
// ==========================================
Route::get('/quiz/questions/{category}/{difficulty}', [QuizController::class, 'getQuestions']);
Route::get('/quiz/statistics', [QuizController::class, 'getStatistics']);
Route::get('/quiz/debug', [QuizController::class, 'debug']);

// ==========================================
// GAME RESULTS
// ==========================================
Route::post('/game/save-challenge-result', [GameController::class, 'saveChallengeResult']);
Route::post('/game/save-battle-result', [GameController::class, 'saveBattleResult']);

// ==========================================
// LEADERBOARD
// ==========================================
Route::get('/leaderboard', [LeaderboardController::class, 'getLeaderboard']);
Route::get('/leaderboard/player/{playerId}', [LeaderboardController::class, 'getPlayerRank']);
Route::get('/players/{playerId}/badges', [LeaderboardController::class, 'getPlayerBadges']);

// ==========================================
// FASTEST TIME RECORDS (Memory Match & Puzzle)
// ==========================================
Route::prefix('game')->group(function () {
    Route::post('/fastest-time', [FastestTimeController::class, 'saveFastestTime']);
    Route::get('/fastest-time/{playerId}/{gameType}/{difficulty}', [FastestTimeController::class, 'getPlayerFastestTime']);
    Route::get('/fastest-time/{playerId}/all', [FastestTimeController::class, 'getPlayerAllRecords']);
    Route::get('/fastest-time/{playerId}/rank', [FastestTimeController::class, 'getPlayerRank']);
    Route::get('/fastest-time/{playerId}/puzzle/{difficulty}/all-categories', [FastestTimeController::class, 'getPlayerPuzzleRecordsByDifficulty']);
    Route::get('/fastest-times/leaderboard', [FastestTimeController::class, 'getGlobalLeaderboard']);
});

// ==========================================
// BADGE & REWARD SYSTEM
// ==========================================
Route::prefix('badges')->group(function () {
    // Get badge summary (progress + unclaimed counts)
    Route::get('/player/{playerId}/summary', [BadgeController::class, 'getPlayerSummary']);

    // Get all rewards (claimed + unclaimed)
    Route::get('/player/{playerId}/rewards', [BadgeController::class, 'getPlayerRewards']);

    // Get only unclaimed rewards (for claim screen)
    Route::get('/player/{playerId}/unclaimed', [BadgeController::class, 'getUnclaimedRewards']);

    // Claim a specific badge
    Route::post('/player/{playerId}/claim', [BadgeController::class, 'claimBadge']);

    // Claim all badges for a difficulty
    Route::post('/player/{playerId}/claim-all', [BadgeController::class, 'claimAllByDifficulty']);
});

// ==========================================
// STARS SYSTEM
// ==========================================
Route::post('/players/{playerId}/stars', [StarsController::class, 'awardStars']);
Route::get('/players/{playerId}/stars', [StarsController::class, 'getPlayerStars']);
Route::get('/players/{playerId}/stars/milestones', [StarsController::class, 'getMilestoneHistory']);
Route::get('/stars/leaderboard', [StarsController::class, 'getStarsLeaderboard']);
Route::get('/players/{playerId}/stars/rank', [StarsController::class, 'getPlayerStarsRank']);

// Temporary cleanup route - remove after use
Route::get('/badges/cleanup/{playerId}', function($playerId) {
    $playerObjectId = new \MongoDB\BSON\ObjectId($playerId);

    // Get player badge record
    $playerBadge = \App\Models\PlayerBadge::where('player_info_id', $playerObjectId)->first();

    if (!$playerBadge) {
        return response()->json(['message' => 'No player badge record found']);
    }

    // Delete invalid unclaimed rewards
    foreach (['easy', 'average', 'difficult'] as $difficulty) {
        $badgeCountField = $difficulty . '_badge_count';
        $currentCount = $playerBadge->$badgeCountField ?? 0;
        $currentInSet = $currentCount % 3;

        if ($currentInSet != 0) {
            // This player should NOT have unclaimed rewards for this difficulty
            $deleted = \Illuminate\Support\Facades\DB::connection('mongodb')
                ->table('player_rewards')
                ->where('player_id', $playerObjectId)
                ->where('difficulty', $difficulty)
                ->where('claimed', false)
                ->delete();

            if ($deleted > 0) {
                \Log::info("Cleaned up {$deleted} invalid {$difficulty} rewards");
            }
        }
    }

    return response()->json(['message' => 'Cleanup complete']);
});
