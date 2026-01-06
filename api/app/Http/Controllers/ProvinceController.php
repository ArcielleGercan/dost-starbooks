<?php

namespace App\Http\Controllers;

class ProvinceController extends Controller
{
    public function getByRegion($regionId)
    {
        $provinces = \DB::connection('mongodb')
            ->table('province')
            ->where('region_id', (int) $regionId)
            ->get()
            ->map(function ($province) {
                return [
                    'id' => (int) $province->id,
                    'province_name' => $province->province_name,
                    'region_id' => (int) $province->region_id,
                ];
            });

        return response()->json($provinces);
    }
}
