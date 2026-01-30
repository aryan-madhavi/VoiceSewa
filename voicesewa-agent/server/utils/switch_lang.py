import os
from dotenv import load_dotenv
from pipecat.pipeline.parallel_pipeline import ParallelPipeline
from pipecat.services.google.tts import GoogleTTSService
from pipecat.processors.filters.function_filter import FunctionFilter
from pipecat.services.llm_service import FunctionCallParams
from pipecat.frames.frames import Frame

load_dotenv(override=True)

GOOGLE_APP_CREDENTIALS=open(os.getenv("GOOGLE_APPLICATION_CREDENTIALS")).read()

class SwitchLanguage(ParallelPipeline):
    def __init__(self):
        self._current_language = "English"

        english_tts = GoogleTTSService(
          credentials=GOOGLE_APP_CREDENTIALS,
          voice_id="en-us-Chirp3-HD-Leda",
        )

        hindi_tts = GoogleTTSService(
          credentials=GOOGLE_APP_CREDENTIALS,
          voice_id="hi-in-Chirp3-HD-Leda",
        )

        marathi_tts = GoogleTTSService(
          credentials=GOOGLE_APP_CREDENTIALS,
          voice_id="mr-in-Chirp3-HD-Leda",
        )

        super().__init__(
            # English
            [FunctionFilter(self.english_filter), english_tts],
            # Hindi
            [FunctionFilter(self.hindi_filter), hindi_tts],
            # Marathi
            [FunctionFilter(self.marathi_filter), marathi_tts],
        )

    @property
    def current_language(self):
        return self._current_language

    async def switch_language(self, params: FunctionCallParams):
        self._current_language = params.arguments["language"]
        await params.result_callback(
            {"system": f"Your answers from now on should be in {self.current_language}."}
        )


    async def english_filter(self, _: Frame) -> bool:
        return self.current_language == "English"
    
    async def hindi_filter(self, _: Frame) -> bool:
        return self.current_language == "Hindi"

    async def marathi_filter(self, _: Frame) -> bool:
        return self.current_language == "Marathi"