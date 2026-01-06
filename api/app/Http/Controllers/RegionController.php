<?php

namespace App\Http\Controllers;

use App\Models\Region;

class RegionController extends Controller
{
    public function index()
    {
        $regions = \DB::connection('mongodb')
        ->table('region')
        ->get()
        ->map(function ($region) {
            return [
                'id' => (int) $region->id,
                'region_name' => $region->region_name,
            ];
        });

        return response()->json($regions);
    }
}
