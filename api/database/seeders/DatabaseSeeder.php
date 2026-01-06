<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use MongoDB\BSON\ObjectId;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run()
    {
        $this->command->info('🌱 Starting database seeding...');

        // 1. Seed Regions
        $this->seedRegions();

        // 2. Seed Provinces
        $this->seedProvinces();

        // 3. Seed Cities
        $this->seedCities();

        // 4. Seed Quiz Questions
        $this->seedQuizQuestions();

        // 5. Seed Players
        $playerIds = $this->seedPlayers();

        // 6. Seed Player Badges
        $this->seedPlayerBadges($playerIds);

        // 7. Seed Player Rewards
        $this->seedPlayerRewards($playerIds);

        // 8. Seed Player Stats
        $this->seedPlayerStats($playerIds);

        // 9. Seed Battle Records
        $this->seedBattles($playerIds);

        // 10. Seed Fastest Times
        $this->seedFastestTimes($playerIds);

        // 11. Seed Star Milestones
        $this->seedStarMilestones($playerIds);

        $this->command->info('✅ Database seeding completed!');
    }

    private function seedRegions()
    {
        $this->command->info('Seeding regions...');

        DB::connection('starbooksWhizbee')->collection('region')->insert([
            ['id' => 1, 'region_name' => 'National Capital Region'],
            ['id' => 2, 'region_name' => 'Region I - Ilocos Region'],
        ]);
    }

    private function seedProvinces()
    {
        $this->command->info('Seeding provinces...');

        DB::connection('starbooksWhizbee')->collection('province')->insert([
            ['id' => 1, 'province_name' => 'Metro Manila', 'region_id' => 1],
            ['id' => 2, 'province_name' => 'Ilocos Norte', 'region_id' => 2],
        ]);
    }

    private function seedCities()
    {
        $this->command->info('Seeding cities...');

        DB::connection('starbooksWhizbee')->collection('city')->insert([
            ['id' => 1, 'city_name' => 'Quezon City', 'province_id' => 1],
            ['id' => 2, 'city_name' => 'Manila', 'province_id' => 1],
        ]);
    }

    private function seedQuizQuestions()
    {
        $this->command->info('Seeding quiz questions...');

        DB::connection('starbooksWhizbee')->collection('quiz_questions')->insert([
            // Math Easy
            [
                'question' => 'What is 5 + 5?',
                'choice_a' => '8',
                'choice_b' => '10',
                'choice_c' => '12',
                'choice_d' => '15',
                'correct_answer' => 'B',
                'category' => 'Math',
                'difficulty_level' => 'Easy',
            ],
            // Math Average
            [
                'question' => 'What is 12 × 8?',
                'choice_a' => '84',
                'choice_b' => '92',
                'choice_c' => '96',
                'choice_d' => '100',
                'correct_answer' => 'C',
                'category' => 'Math',
                'difficulty_level' => 'Average',
            ],
            // Science Easy
            [
                'question' => 'What is the largest planet in our solar system?',
                'choice_a' => 'Earth',
                'choice_b' => 'Mars',
                'choice_c' => 'Jupiter',
                'choice_d' => 'Saturn',
                'correct_answer' => 'C',
                'category' => 'Science',
                'difficulty_level' => 'Easy',
            ],
            // Science Difficult
            [
                'question' => 'What is the chemical symbol for Gold?',
                'choice_a' => 'Go',
                'choice_b' => 'Au',
                'choice_c' => 'Gd',
                'choice_d' => 'Ag',
                'correct_answer' => 'B',
                'category' => 'Science',
                'difficulty_level' => 'Difficult',
            ],
        ]);
    }

    private function seedPlayers()
    {
        $this->command->info('Seeding players...');

        $player1Id = new ObjectId();
        $player2Id = new ObjectId();

        DB::connection('starbooksWhizbee')->collection('player_info')->insert([
            [
                '_id' => $player1Id,
                'username' => 'player1',
                'password' => Hash::make('password123'),
                'school' => 'Test School',
                'age' => 12,
                'category' => 'Student',
                'sex' => 'Male',
                'region' => 1,
                'province' => 1,
                'city' => 1,
                'avatar' => 'assets/images-avatars/Adventurer.png',
                'stars' => 75,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                '_id' => $player2Id,
                'username' => 'player2',
                'password' => Hash::make('password123'),
                'school' => 'Another School',
                'age' => 13,
                'category' => 'Student',
                'sex' => 'Female',
                'region' => 2,
                'province' => 2,
                'city' => 2,
                'avatar' => 'assets/images-avatars/Explorer.png',
                'stars' => 150,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        return [$player1Id, $player2Id];
    }

    private function seedPlayerBadges($playerIds)
    {
        $this->command->info('Seeding player badges...');

        DB::connection('starbooksWhizbee')->collection('player_badges')->insert([
            [
                'player_info_id' => $playerIds[0],
                'easy_badge_count' => 5,
                'average_badge_count' => 3,
                'difficult_badge_count' => 1,
                'easy_official_badge' => 1,
                'average_official_badge' => 1,
                'difficult_official_badge' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'player_info_id' => $playerIds[1],
                'easy_badge_count' => 8,
                'average_badge_count' => 6,
                'difficult_badge_count' => 4,
                'easy_official_badge' => 2,
                'average_official_badge' => 2,
                'difficult_official_badge' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }

    private function seedPlayerRewards($playerIds)
    {
        $this->command->info('Seeding player rewards...');

        DB::connection('starbooksWhizbee')->collection('player_rewards')->insert([
            // Player 1 - Unclaimed easy badge
            [
                'player_id' => $playerIds[0],
                'difficulty' => 'easy',
                'badge_number' => 1,
                'earned_date' => now()->subDays(2),
                'claimed' => false,
                'claimed_date' => null,
                'created_at' => now()->subDays(2),
                'updated_at' => now()->subDays(2),
            ],
            // Player 1 - Claimed average badge
            [
                'player_id' => $playerIds[0],
                'difficulty' => 'average',
                'badge_number' => 1,
                'earned_date' => now()->subDays(5),
                'claimed' => true,
                'claimed_date' => now()->subDays(3),
                'created_at' => now()->subDays(5),
                'updated_at' => now()->subDays(3),
            ],
            // Player 2 - Unclaimed difficult badge
            [
                'player_id' => $playerIds[1],
                'difficulty' => 'difficult',
                'badge_number' => 1,
                'earned_date' => now()->subDay(),
                'claimed' => false,
                'claimed_date' => null,
                'created_at' => now()->subDay(),
                'updated_at' => now()->subDay(),
            ],
            // Player 2 - Claimed easy badge
            [
                'player_id' => $playerIds[1],
                'difficulty' => 'easy',
                'badge_number' => 2,
                'earned_date' => now()->subDays(7),
                'claimed' => true,
                'claimed_date' => now()->subDays(6),
                'created_at' => now()->subDays(7),
                'updated_at' => now()->subDays(6),
            ],
        ]);
    }

    private function seedPlayerStats($playerIds)
    {
        $this->command->info('Seeding player stats...');

        DB::connection('starbooksWhizbee')->collection('player_stats')->insert([
            [
                'player_id' => $playerIds[0],
                'username' => 'player1',
                'avatar' => 'assets/images-avatars/Adventurer.png',
                'challenge_stats' => [
                    'math' => ['easy' => 5, 'average' => 3, 'difficult' => 1],
                    'science' => ['easy' => 2, 'average' => 1],
                ],
                'battle_stats' => [
                    'math' => ['easy' => 3, 'average' => 2],
                    'science' => ['easy' => 1],
                ],
                'memory_match_stats' => [
                    'general' => ['easy' => 10, 'average' => 5],
                ],
                'puzzle_stats' => [
                    'solar system' => ['easy' => 8, 'average' => 4],
                ],
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'player_id' => $playerIds[1],
                'username' => 'player2',
                'avatar' => 'assets/images-avatars/Explorer.png',
                'challenge_stats' => [
                    'math' => ['easy' => 8, 'average' => 6, 'difficult' => 4],
                    'science' => ['easy' => 5, 'average' => 3],
                ],
                'battle_stats' => [
                    'math' => ['easy' => 10, 'average' => 8],
                    'science' => ['easy' => 6, 'average' => 4],
                ],
                'memory_match_stats' => [
                    'general' => ['easy' => 15, 'average' => 10, 'difficult' => 5],
                ],
                'puzzle_stats' => [
                    'solar system' => ['easy' => 12, 'average' => 8, 'difficult' => 3],
                ],
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }

    private function seedBattles($playerIds)
    {
        $this->command->info('Seeding battle records...');

        DB::connection('starbooksWhizbee')->collection('battle')->insert([
            [
                'player_id' => $playerIds[0],
                'battle_id' => 'BTL-' . uniqid(),
                'opponent_id' => $playerIds[1],
                'opponent_username' => 'player2',
                'opponent_score' => 8,
                'category' => 'Math',
                'difficulty_level' => 'Easy',
                'player_score' => 10,
                'result' => 'won',
                'questions_answered' => 10,
                'correct_answers' => 10,
                'created_at' => now()->subDay(),
                'updated_at' => now()->subDay(),
            ],
            [
                'player_id' => $playerIds[1],
                'battle_id' => 'BTL-' . uniqid(),
                'opponent_id' => $playerIds[0],
                'opponent_username' => 'player1',
                'opponent_score' => 9,
                'category' => 'Science',
                'difficulty_level' => 'Average',
                'player_score' => 7,
                'result' => 'lost',
                'questions_answered' => 10,
                'correct_answers' => 7,
                'created_at' => now()->subHours(12),
                'updated_at' => now()->subHours(12),
            ],
        ]);
    }

    private function seedFastestTimes($playerIds)
    {
        $this->command->info('Seeding fastest times...');

        // Memory Match records
        DB::connection('starbooksWhizbee')->collection('fastest_time_memory_match')->insert([
            [
                'player_id' => $playerIds[0],
                'player_username' => 'player1',
                'game_type' => 'memory_match',
                'difficulty' => 'EASY',
                'category' => null,
                'time_seconds' => 45,
                'moves' => 12,
                'achieved_at' => now()->subDays(3),
                'created_at' => now()->subDays(3),
                'updated_at' => now()->subDays(3),
            ],
            [
                'player_id' => $playerIds[1],
                'player_username' => 'player2',
                'game_type' => 'memory_match',
                'difficulty' => 'EASY',
                'category' => null,
                'time_seconds' => 38,
                'moves' => 10,
                'achieved_at' => now()->subDays(2),
                'created_at' => now()->subDays(2),
                'updated_at' => now()->subDays(2),
            ],
        ]);

        // Puzzle records
        DB::connection('starbooksWhizbee')->collection('fastest_time_puzzle')->insert([
            [
                'player_id' => $playerIds[0],
                'player_username' => 'player1',
                'game_type' => 'puzzle',
                'difficulty' => 'EASY',
                'category' => 'Solar System',
                'time_seconds' => 120,
                'moves' => 25,
                'achieved_at' => now()->subDays(4),
                'created_at' => now()->subDays(4),
                'updated_at' => now()->subDays(4),
            ],
            [
                'player_id' => $playerIds[1],
                'player_username' => 'player2',
                'game_type' => 'puzzle',
                'difficulty' => 'AVERAGE',
                'category' => 'Solar System',
                'time_seconds' => 180,
                'moves' => 35,
                'achieved_at' => now()->subDay(),
                'created_at' => now()->subDay(),
                'updated_at' => now()->subDay(),
            ],
        ]);
    }

    private function seedStarMilestones($playerIds)
    {
        $this->command->info('Seeding star milestones...');

        DB::connection('starbooksWhizbee')->collection('star_milestones')->insert([
            [
                'player_id' => $playerIds[0],
                'tier' => 'Bronze',
                'icon' => '🥉',
                'prize' => 'Bronze Badge Unlocked!',
                'stars_at_achievement' => 50,
                'achieved_at' => now()->subDays(10),
            ],
            [
                'player_id' => $playerIds[1],
                'tier' => 'Bronze',
                'icon' => '🥉',
                'prize' => 'Bronze Badge Unlocked!',
                'stars_at_achievement' => 50,
                'achieved_at' => now()->subDays(15),
            ],
            [
                'player_id' => $playerIds[1],
                'tier' => 'Silver',
                'icon' => '🥈',
                'prize' => 'Silver Badge Unlocked!',
                'stars_at_achievement' => 100,
                'achieved_at' => now()->subDays(8),
            ],
        ]);
    }
}
